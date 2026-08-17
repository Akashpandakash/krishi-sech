import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { AppError } from '../../common/app-error.js';
import type {
  PushDeliveryProvider,
  PushDeliveryResult,
  PushMessage,
} from '../providers/push-delivery-provider.js';
import type {
  BroadcastAudience,
  BroadcastInput,
} from '../repositories/broadcast-repository.js';
import { BroadcastService } from './broadcast-service.js';
import { InMemoryBroadcastRepository } from '../../testing/repository-fakes.js';

const audience: BroadcastAudience = {
  language: null,
  state: null,
  farmerType: null,
  onlyActive: true,
};

function draft(overrides: Partial<BroadcastInput> = {}): BroadcastInput {
  return {
    title: 'Heavy rain tomorrow',
    body: 'Hold irrigation for 24 hours in your district.',
    category: 'weather',
    deepLink: null,
    audience,
    scheduledAt: null,
    createdByAdminId: 'admin-1',
    createdByAdminEmail: 'owner@example.com',
    ...overrides,
  };
}

class RecordingPushProvider implements PushDeliveryProvider {
  readonly name = 'recording';
  readonly configured = true;
  readonly sent: { tokens: string[]; message: PushMessage }[] = [];

  constructor(private readonly result: Partial<PushDeliveryResult> = {}) {}

  async send(tokens: string[], message: PushMessage): Promise<PushDeliveryResult> {
    this.sent.push({ tokens, message });
    return {
      delivered: tokens.length,
      failed: 0,
      staleTokens: [],
      failureReason: null,
      ...this.result,
    };
  }
}

/** Mirrors the Mongo repository's token lookup without needing a database. */
class TokenBackedRepository extends InMemoryBroadcastRepository {
  removedTokens: string[] = [];

  constructor(private readonly tokens: string[]) {
    super();
  }

  override async audienceDeviceTokens(): Promise<string[]> {
    return this.tokens;
  }

  override async removeTokens(tokens: string[]): Promise<void> {
    this.removedTokens.push(...tokens);
  }
}

describe('broadcast delivery', () => {
  it('sends to every audience device and records the counts', async () => {
    const repository = new TokenBackedRepository(['token-a', 'token-b']);
    const push = new RecordingPushProvider();
    const service = new BroadcastService(repository, push);

    const broadcast = await service.create(draft(), true);

    assert.equal(broadcast.status, 'sent');
    assert.equal(broadcast.audienceCount, 2);
    assert.equal(broadcast.deliveredCount, 2);
    assert.equal(broadcast.failedCount, 0);
    assert.ok(broadcast.sentAt);
    assert.deepEqual(push.sent[0]!.tokens, ['token-a', 'token-b']);
    assert.equal(push.sent[0]!.message.data.broadcastId, broadcast.id);
    assert.equal(push.sent[0]!.message.data.category, 'weather');
  });

  it('prunes tokens the transport reports as dead', async () => {
    const repository = new TokenBackedRepository(['live', 'dead']);
    const service = new BroadcastService(
      repository,
      new RecordingPushProvider({
        delivered: 1,
        failed: 1,
        staleTokens: ['dead'],
        failureReason: 'FCM 404: UNREGISTERED',
      }),
    );

    const broadcast = await service.create(draft(), true);

    assert.deepEqual(repository.removedTokens, ['dead']);
    assert.equal(broadcast.deliveredCount, 1);
    assert.equal(broadcast.failedCount, 1);
    assert.equal(broadcast.failureReason, 'FCM 404: UNREGISTERED');
    // A push failure must not hide the message from the in-app inbox.
    assert.equal(broadcast.status, 'sent');
  });

  it('keeps a draft unsent until it is explicitly sent', async () => {
    const repository = new TokenBackedRepository(['token-a']);
    const push = new RecordingPushProvider();
    const service = new BroadcastService(repository, push);

    const created = await service.create(draft(), false);
    assert.equal(created.status, 'draft');
    assert.equal(push.sent.length, 0);

    const sent = await service.send(created.id);
    assert.equal(sent.status, 'sent');
    assert.equal(push.sent.length, 1);

    await assert.rejects(
      service.send(created.id),
      (error: AppError) => error.code === 'BROADCAST_ALREADY_SENT',
    );
  });

  it('rejects a schedule in the past', async () => {
    const service = new BroadcastService(
      new TokenBackedRepository([]),
      new RecordingPushProvider(),
    );
    await assert.rejects(
      service.create(
        draft({ scheduledAt: new Date(Date.now() - 60_000) }),
        false,
      ),
      (error: AppError) => error.code === 'SCHEDULE_IN_PAST',
    );
  });

  it('dispatches a scheduled broadcast only once its time has passed', async () => {
    const repository = new TokenBackedRepository(['token-a']);
    const push = new RecordingPushProvider();
    const service = new BroadcastService(repository, push);
    const scheduledAt = new Date(Date.now() + 60_000);

    const scheduled = await service.create(draft({ scheduledAt }), false);
    assert.equal(scheduled.status, 'scheduled');

    assert.equal(await service.dispatchScheduled(new Date()), 0);
    assert.equal(push.sent.length, 0);

    assert.equal(
      await service.dispatchScheduled(new Date(scheduledAt.getTime() + 1000)),
      1,
    );
    assert.equal((await service.get(scheduled.id)).status, 'sent');
    assert.equal(push.sent.length, 1);
  });

  it('cancels a scheduled broadcast before it goes out', async () => {
    const repository = new TokenBackedRepository(['token-a']);
    const push = new RecordingPushProvider();
    const service = new BroadcastService(repository, push);
    const scheduled = await service.create(
      draft({ scheduledAt: new Date(Date.now() + 60_000) }),
      false,
    );

    assert.equal((await service.cancel(scheduled.id)).status, 'cancelled');
    assert.equal(await service.dispatchScheduled(new Date(Date.now() + 120_000)), 0);
    assert.equal(push.sent.length, 0);
  });
});

describe('notification inbox', () => {
  it('lists sent broadcasts and tracks read state per user', async () => {
    const repository = new TokenBackedRepository([]);
    const service = new BroadcastService(repository, new RecordingPushProvider());
    const broadcast = await service.create(draft(), true);

    assert.equal(await service.countUnread('user-1'), 1);
    const [item] = await service.inbox('user-1', 10);
    assert.equal(item!.id, broadcast.id);
    assert.equal(item!.read, false);

    await service.markRead(broadcast.id, 'user-1');
    assert.equal(await service.countUnread('user-1'), 0);
    // Another farmer's inbox is unaffected.
    assert.equal(await service.countUnread('user-2'), 1);
  });

  it('never shows a draft in the inbox', async () => {
    const service = new BroadcastService(
      new TokenBackedRepository([]),
      new RecordingPushProvider(),
    );
    await service.create(draft(), false);
    assert.deepEqual(await service.inbox('user-1', 10), []);
  });
});
