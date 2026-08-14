import type { Metadata } from 'next';

import { DeleteAccountFlow } from '@/components/site/delete-account-flow';
import { PlaceholderWarning } from '@/components/site/chrome';
import { siteConfig } from '@/lib/site-config';

export const metadata: Metadata = {
  title: 'Delete your account',
  description:
    'Request deletion of your Krishi Sech account and every record attached to it. No app install required.',
};

const ERASED = [
  ['Your account', 'phone number, email, name, language and login sessions'],
  ['Your farm profile', 'farm name, land area, soil type, irrigation source and location'],
  ['Your crops', 'every crop you tracked, with its variety, stage and health history'],
  ['Your calendar', 'all scheduled and completed tasks and their reminders'],
  ['Your advice history', 'saved fertilizer and irrigation recommendations'],
  ['Your devices', 'push notification registrations and delivery receipts'],
];

export default function DeleteAccountPage() {
  return (
    <main id="main" className="shell doc">
      <div className="glass panel stack doc__card">
        <PlaceholderWarning />

        <header className="stack" style={{ gap: '0.35rem' }}>
          <p className="eyebrow">Account &amp; data deletion</p>
          <h1 className="h1 doc__title">Delete your account</h1>
          <p className="lede">
            You can permanently delete your {siteConfig.appName} account and
            everything stored against it from this page. You do not need to
            install the app, and you do not need to contact anyone first.
          </p>
        </header>

        <div className="doc__body">
          <h2>What gets deleted</h2>
          <p>
            Deletion is immediate and permanent. There is no grace period and no
            way for us to restore the data afterwards, so please be certain
            before you confirm.
          </p>
          <div className="table-scroll">
            <table className="doc__table">
              <thead>
                <tr>
                  <th scope="col">Data</th>
                  <th scope="col">Includes</th>
                </tr>
              </thead>
              <tbody>
                {ERASED.map(([what, detail]) => (
                  <tr key={what}>
                    <th scope="row">{what}</th>
                    <td>{detail}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <h2>What may be kept, and why</h2>
          <p>
            Crop photographs you submitted for disease analysis are not stored on
            our servers after the analysis returns, so there is nothing to
            delete. Anonymous, aggregated counts — for example &ldquo;how many
            farms grow wheat&rdquo; — contain nothing that identifies you and are
            not removed. Where we are legally required to retain a record of a
            deletion request, we keep only the fact that a request was made and
            when.
          </p>

          <h2>Delete your account now</h2>
          <p>
            Enter the phone number you use to sign in. We will send a one-time
            code to confirm the number is yours, because otherwise anyone who
            knew your number could erase your farm records.
          </p>
        </div>

        <DeleteAccountFlow />

        <div className="doc__body">
          <h2>Other ways to delete your account</h2>
          <p>
            You can also delete your account from inside the app, under
            Profile → Delete account. If you cannot access either route, email{' '}
            <a href={`mailto:${siteConfig.supportEmail}`}>
              {siteConfig.supportEmail}
            </a>{' '}
            from the address on your account, or include your registered phone
            number, and we will complete the deletion for you.
          </p>
        </div>
      </div>
    </main>
  );
}
