import assert from 'node:assert/strict';
import { generateKeyPairSync, type KeyObject } from 'node:crypto';
import { describe, it } from 'node:test';

import jwt from 'jsonwebtoken';

import { AppError } from '../../common/app-error.js';
import { GoogleIdTokenVerifier } from './google-id-token-verifier.js';

const audience = 'server-client-id.apps.googleusercontent.com';
const issuer = 'https://accounts.google.com';

const signing = generateKeyPairSync('rsa', { modulusLength: 2048 });
const attacker = generateKeyPairSync('rsa', { modulusLength: 2048 });

function jwks(publicKey: KeyObject, keyId: string) {
  return {
    keys: [
      {
        ...(publicKey.export({ format: 'jwk' }) as Record<string, unknown>),
        kid: keyId,
        alg: 'RS256',
        use: 'sig',
      },
    ],
  };
}

/** Counts calls so the key cache can be asserted on. */
function stubFetch(body: unknown, maxAgeSeconds = 3600) {
  const calls = { count: 0 };
  const implementation = (async () => {
    calls.count += 1;
    return new Response(JSON.stringify(body), {
      status: 200,
      headers: {
        'content-type': 'application/json',
        'cache-control': `public, max-age=${maxAgeSeconds}`,
      },
    });
  }) as unknown as typeof fetch;
  return { implementation, calls };
}

function token(
  overrides: Record<string, unknown> = {},
  options: { key?: KeyObject; keyId?: string } = {},
) {
  const payload = {
    email: 'Farmer@Example.com',
    email_verified: true,
    name: 'Amit Farmer',
    picture: 'https://example.com/a.jpg',
    ...overrides,
  };
  return jwt.sign(payload, options.key ?? signing.privateKey, {
    algorithm: 'RS256',
    keyid: options.keyId ?? 'key-1',
    subject: '1234567890',
    audience,
    issuer,
    expiresIn: 600,
  });
}

function verifier(audiences: string[] = [audience], fetchStub = stubFetch(jwks(signing.publicKey, 'key-1'))) {
  return {
    instance: new GoogleIdTokenVerifier(audiences, 10_000, fetchStub.implementation),
    calls: fetchStub.calls,
  };
}

async function rejects(promise: Promise<unknown>, code: string, status: number) {
  await assert.rejects(promise, (error: unknown) => {
    assert.ok(error instanceof AppError, `expected AppError, got ${error}`);
    assert.equal(error.code, code);
    assert.equal(error.statusCode, status);
    return true;
  });
}

describe('Google ID token verification', () => {
  it('accepts a correctly signed token and normalizes the identity', async () => {
    const { instance } = verifier();
    const identity = await instance.verify(token());
    assert.equal(identity.googleId, '1234567890');
    assert.equal(identity.email, 'farmer@example.com');
    assert.equal(identity.name, 'Amit Farmer');
    assert.equal(identity.profilePhotoUrl, 'https://example.com/a.jpg');
  });

  it('rejects a token signed by a different key', async () => {
    const { instance } = verifier();
    await rejects(
      instance.verify(token({}, { key: attacker.privateKey })),
      'GOOGLE_TOKEN_INVALID',
      401,
    );
  });

  it('rejects a token minted for another audience', async () => {
    const { instance } = verifier(['a-different-client-id']);
    await rejects(instance.verify(token()), 'GOOGLE_TOKEN_INVALID', 401);
  });

  it('rejects a token from an untrusted issuer', async () => {
    const { instance } = verifier();
    const forged = jwt.sign(
      { email: 'f@example.com', email_verified: true },
      signing.privateKey,
      {
        algorithm: 'RS256',
        keyid: 'key-1',
        subject: '1',
        audience,
        issuer: 'https://evil.example.com',
        expiresIn: 600,
      },
    );
    await rejects(instance.verify(forged), 'GOOGLE_TOKEN_INVALID', 401);
  });

  it('rejects an expired token', async () => {
    const { instance } = verifier();
    const expired = jwt.sign(
      { email: 'f@example.com', email_verified: true },
      signing.privateKey,
      {
        algorithm: 'RS256',
        keyid: 'key-1',
        subject: '1',
        audience,
        issuer,
        expiresIn: -60,
      },
    );
    await rejects(instance.verify(expired), 'GOOGLE_TOKEN_INVALID', 401);
  });

  it('refuses an unverified email so an account cannot be claimed', async () => {
    const { instance } = verifier();
    await rejects(
      instance.verify(token({ email_verified: false })),
      'GOOGLE_TOKEN_INVALID',
      401,
    );
  });

  it('accepts the string form of email_verified Google sometimes sends', async () => {
    const { instance } = verifier();
    const identity = await instance.verify(token({ email_verified: 'true' }));
    assert.equal(identity.email, 'farmer@example.com');
  });

  it('rejects a token whose key id is unknown even after a refresh', async () => {
    const { instance } = verifier();
    await rejects(
      instance.verify(token({}, { keyId: 'rotated-away' })),
      'GOOGLE_TOKEN_INVALID',
      401,
    );
  });

  it('caches signing keys instead of fetching per verification', async () => {
    const stub = stubFetch(jwks(signing.publicKey, 'key-1'));
    const instance = new GoogleIdTokenVerifier(
      [audience],
      10_000,
      stub.implementation,
    );
    await instance.verify(token());
    await instance.verify(token());
    await instance.verify(token());
    assert.equal(stub.calls.count, 1);
  });

  it('reports unavailable rather than invalid when not configured', async () => {
    const { instance } = verifier([]);
    await rejects(instance.verify(token()), 'GOOGLE_LOGIN_UNAVAILABLE', 503);
    assert.equal(instance.configured, false);
  });

  it('reports unavailable when Google keys cannot be fetched', async () => {
    const failing = (async () => {
      throw new Error('network down');
    }) as unknown as typeof fetch;
    const instance = new GoogleIdTokenVerifier([audience], 10_000, failing);
    await rejects(instance.verify(token()), 'GOOGLE_LOGIN_UNAVAILABLE', 503);
  });
});
