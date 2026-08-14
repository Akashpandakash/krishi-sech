import type { Metadata } from 'next';
import Link from 'next/link';

import { DocPage } from '@/components/site/chrome';
import { siteConfig } from '@/lib/site-config';

export const metadata: Metadata = {
  title: 'Data safety summary',
  description:
    'A plain summary of what Krishi Sech collects, whether it is shared, and whether it can be deleted — matching the Google Play Data safety disclosure.',
};

/** Mirrors the categories in Google Play's Data safety form so the listing and
 *  this page cannot drift apart. */
const ROWS = [
  {
    type: 'Phone number',
    collected: 'Yes',
    shared: 'Yes — SMS provider, to deliver your code',
    purpose: 'Account management',
    optional: 'Required',
  },
  {
    type: 'Email address',
    collected: 'Only with Google sign-in',
    shared: 'No',
    purpose: 'Account management',
    optional: 'Optional',
  },
  {
    type: 'Name',
    collected: 'Yes',
    shared: 'No',
    purpose: 'App functionality',
    optional: 'Optional',
  },
  {
    type: 'Approximate location',
    collected: 'Only with permission',
    shared: 'Coordinates only, to the weather provider',
    purpose: 'App functionality',
    optional: 'Optional',
  },
  {
    type: 'Photos',
    collected: 'Only when you scan a crop',
    shared: 'Yes — AI provider, for diagnosis',
    purpose: 'App functionality',
    optional: 'Optional. Not stored after analysis',
  },
  {
    type: 'App activity (screens viewed)',
    collected: 'Yes',
    shared: 'Yes — Google Analytics for Firebase',
    purpose: 'Analytics',
    optional: 'Required in published builds',
  },
  {
    type: 'Crash logs and diagnostics',
    collected: 'Yes',
    shared: 'Yes — Firebase Crashlytics',
    purpose: 'Crash reporting and debugging',
    optional: 'Required in published builds',
  },
  {
    type: 'Other user content (farm, crops, tasks)',
    collected: 'Yes',
    shared: 'Sent to the AI provider as context when you ask a question',
    purpose: 'App functionality',
    optional: 'Optional',
  },
];

export default function DataSafetyPage() {
  return (
    <DocPage
      title="Data safety summary"
      updated={siteConfig.policyLastUpdated}
      intro={`A short version of the ${siteConfig.appName} privacy policy, in the same categories Google Play uses on the store listing.`}
    >
      <h2>The short version</h2>
      <ul>
        <li>Your data is encrypted in transit.</li>
        <li>You can request that your data be deleted, and do it yourself.</li>
        <li>
          We do not sell your data, and we do not share it with advertisers or
          data brokers.
        </li>
        <li>
          We do not collect financial information, government identifiers, land
          records, contacts, messages or your browsing history.
        </li>
        <li>Crop photographs are not stored after the diagnosis is returned.</li>
      </ul>

      <h2>Data collected</h2>
      <div className="table-scroll">
        <table className="doc__table">
          <thead>
            <tr>
              <th scope="col">Data type</th>
              <th scope="col">Collected</th>
              <th scope="col">Shared</th>
              <th scope="col">Purpose</th>
              <th scope="col">Required</th>
            </tr>
          </thead>
          <tbody>
            {ROWS.map((row) => (
              <tr key={row.type}>
                <th scope="row">{row.type}</th>
                <td>{row.collected}</td>
                <td>{row.shared}</td>
                <td>{row.purpose}</td>
                <td>{row.optional}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2>Deletion</h2>
      <p>
        You can delete your account and all of the data above from{' '}
        <Link href="/delete-account">the account deletion page</Link>, without
        installing the app, or from inside the app under Profile → Delete
        account. Deletion is immediate and permanent.
      </p>

      <h2>Full detail</h2>
      <p>
        This page is a summary. The{' '}
        <Link href="/privacy">Privacy Policy</Link> is the complete statement,
        including who each provider is and how long data is kept.
      </p>
    </DocPage>
  );
}
