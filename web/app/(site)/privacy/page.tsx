import type { Metadata } from 'next';
import Link from 'next/link';

import { DocPage } from '@/components/site/chrome';
import { siteConfig } from '@/lib/site-config';

export const metadata: Metadata = {
  title: 'Privacy Policy',
  description:
    'What Krishi Sech collects, why, who it is shared with, and how to delete it.',
};

const COLLECTED = [
  {
    what: 'Phone number',
    when: 'When you sign in. This is the identifier for your account.',
    why: 'To create and secure your account and send the one-time code that signs you in.',
  },
  {
    what: 'Email address and Google account ID',
    when: 'Only if you choose Sign in with Google.',
    why: 'To identify your account. We receive these from Google; we never receive your Google password.',
  },
  {
    what: 'Name and preferred language',
    when: 'When you set up your profile, or change the app language.',
    why: 'To address you correctly and show the app, reminders and advice in your language.',
  },
  {
    what: 'Approximate location',
    when: 'Only when you grant location permission, or type a location manually.',
    why: 'To fetch weather for your area and tailor seasonal advice. We store the village, district and state, not a continuous trail of your movements.',
  },
  {
    what: 'Farm profile',
    when: 'When you fill in your farm details.',
    why: 'Farm size, soil type and irrigation source are what make fertilizer and irrigation recommendations specific to your land rather than generic.',
  },
  {
    what: 'Crops and calendar tasks',
    when: 'When you add a crop or a task.',
    why: 'To keep your crop calendar and send reminders at the right time in the season.',
  },
  {
    what: 'Crop photographs',
    when: 'Only when you take or choose a photo for disease analysis.',
    why: 'To diagnose the problem. See “Crop photographs” below for exactly what happens to the image.',
  },
  {
    what: 'Questions you ask the assistant',
    when: 'When you use the in-app assistant.',
    why: 'To answer them. Your farm’s crops, location and current weather are sent along with the question so the answer is relevant.',
  },
  {
    what: 'Notification registration',
    when: 'If you allow notifications.',
    why: 'A device token so reminders and announcements reach your phone. It identifies the device, not you personally.',
  },
  {
    what: 'Crash reports and usage analytics',
    when: 'Automatically, in the published app.',
    why: 'Crash reports tell us the app broke and where. Analytics tells us which screens are used. Both carry your account identifier so we can connect a crash to a support request.',
  },
];

const PROCESSORS = [
  {
    name: 'Google Firebase',
    role: 'Push notifications, crash reporting, usage analytics',
    data: 'Device token, crash diagnostics, screen names, account identifier',
  },
  {
    name: 'Google (Gemini) or OpenAI',
    role: 'Disease diagnosis from photos, and assistant answers',
    data: 'The crop photo, your question, and your farm context (crops, coarse location, weather)',
  },
  {
    name: 'SMS delivery provider',
    role: 'Sending the one-time sign-in and deletion codes',
    data: 'Your phone number and the code',
  },
  {
    name: 'Open-Meteo',
    role: 'Weather forecasts',
    data: 'Approximate coordinates only — no account identifier is sent',
  },
  {
    name: 'Database and application hosting',
    role: 'Running the service and storing your records',
    data: 'All account data described above',
  },
];

export default function PrivacyPage() {
  return (
    <DocPage
      title="Privacy Policy"
      updated={siteConfig.policyLastUpdated}
      intro={`This policy explains what ${siteConfig.appName} collects, why it is collected, who it is shared with, and how to get it deleted. It covers the ${siteConfig.appName} mobile app and this website.`}
    >
      <h2>Who is responsible for your data</h2>
      <p>
        {siteConfig.appName} is operated from {siteConfig.registeredAddress}.
        The operator, {siteConfig.legalEntity}, is the controller of the
        personal data described here. For any privacy question, or to exercise
        the rights below, write to{' '}
        <a href={`mailto:${siteConfig.privacyEmail}`}>{siteConfig.privacyEmail}</a>.
      </p>

      <h2>What we collect and why</h2>
      <p>
        We collect only what the app needs to do its job. We do not ask for your
        Aadhaar, bank details, land records or any government identifier.
      </p>
      <div className="table-scroll">
        <table className="doc__table">
          <thead>
            <tr>
              <th scope="col">Data</th>
              <th scope="col">When it is collected</th>
              <th scope="col">Why</th>
            </tr>
          </thead>
          <tbody>
            {COLLECTED.map((row) => (
              <tr key={row.what}>
                <th scope="row">{row.what}</th>
                <td>{row.when}</td>
                <td>{row.why}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2>Crop photographs</h2>
      <p>
        When you photograph a crop for disease analysis, the image is sent to our
        server and forwarded to an AI vision provider, together with context
        about your farm — your crops, their growth stage, your approximate
        location and the current weather — because a diagnosis is far more
        accurate with that context than without it.
      </p>
      <p>
        <strong>The photograph is not saved on our servers.</strong> It is held
        in memory for the length of the request and discarded once the diagnosis
        is returned to your phone. We do not build a photo library, and we do not
        use your photographs to train any model.
      </p>

      <h2>Location</h2>
      <p>
        Location is optional. If you decline the permission, the app still works
        — you can type your district manually, and everything except automatic
        local weather behaves the same.
      </p>
      <p>
        When you do grant it, we resolve the coordinates to a place name and
        store the village, district and state on your profile. We do not record a
        history of where you have been, and we do not track you in the
        background.
      </p>

      <h2>Who your data is shared with</h2>
      <p>
        We do not sell your personal data. We do not share it with advertisers,
        data brokers, input dealers, lenders or insurers. It is shared only with
        the service providers below, only to the extent they need it to perform
        their function for us.
      </p>
      <div className="table-scroll">
        <table className="doc__table">
          <thead>
            <tr>
              <th scope="col">Provider</th>
              <th scope="col">What they do</th>
              <th scope="col">What they receive</th>
            </tr>
          </thead>
          <tbody>
            {PROCESSORS.map((row) => (
              <tr key={row.name}>
                <th scope="row">{row.name}</th>
                <td>{row.role}</td>
                <td>{row.data}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p>
        We may also disclose data where we are legally required to, for example
        in response to a valid order from a court or authority.
      </p>

      <h2>How long we keep it</h2>
      <p>
        Your account data is kept while your account exists. When you delete your
        account it is erased immediately — see below. Crop photographs are never
        retained past the analysis. Crash reports and analytics are retained by
        Google Firebase according to its own retention periods, which are
        measured in months rather than years.
      </p>

      <h2>Deleting your account and your data</h2>
      <p>
        You can delete your account and everything attached to it at any time,
        without asking us and without installing the app:
      </p>
      <ul>
        <li>
          On the web, at{' '}
          <Link href="/delete-account">{siteConfig.appName} → Delete account</Link>.
          You confirm with a one-time code sent to your number.
        </li>
        <li>In the app, under Profile → Delete account.</li>
        <li>
          By emailing{' '}
          <a href={`mailto:${siteConfig.privacyEmail}`}>
            {siteConfig.privacyEmail}
          </a>{' '}
          from your registered address, or quoting your registered phone number.
        </li>
      </ul>
      <p>
        Deletion is immediate and permanent. It removes your account, farm
        profile, crops, calendar tasks, saved recommendations, device
        registrations and sessions. We cannot restore an account afterwards.
      </p>

      <h2>Your rights</h2>
      <p>
        You can ask us to give you a copy of your data, correct anything that is
        wrong, delete your account, or object to a particular use. Most of this
        you can do yourself in the app; for anything else, write to{' '}
        <a href={`mailto:${siteConfig.privacyEmail}`}>{siteConfig.privacyEmail}</a>{' '}
        and we will respond within 30 days. You can withdraw location or
        notification permission at any time in your phone’s settings, without
        losing your account.
      </p>

      <h2>Children</h2>
      <p>
        {siteConfig.appName} is intended for adults managing farmland and is not
        directed at children. We do not knowingly collect data from anyone under
        13. If you believe a child has created an account, write to us and we
        will delete it.
      </p>

      <h2>Security</h2>
      <p>
        Traffic between the app and our servers is encrypted in transit. Sign-in
        tokens are held in your device’s secure storage. Access to production
        data is limited to the people who operate the service, and privileged
        actions are recorded in an audit log. No system is perfectly secure, but
        we do not ask for or hold the categories of data that would make an
        incident severe — there are no payment details, government identifiers or
        land records in {siteConfig.appName}.
      </p>

      <h2>Where your data is processed</h2>
      <p>
        Our servers and database are operated in the regions of our hosting
        provider. Some service providers listed above, in particular the AI and
        Firebase services, process data on infrastructure outside India. In each
        case the transfer is limited to what that provider needs to perform its
        function.
      </p>

      <h2>Changes to this policy</h2>
      <p>
        If we change what we collect or who we share it with, we will update this
        page and change the date at the top. Material changes will also be
        announced in the app.
      </p>

      <h2>Contact</h2>
      <p>
        Privacy questions:{' '}
        <a href={`mailto:${siteConfig.privacyEmail}`}>{siteConfig.privacyEmail}</a>
        <br />
        General support:{' '}
        <a href={`mailto:${siteConfig.supportEmail}`}>{siteConfig.supportEmail}</a>
        <br />
        Postal address: {siteConfig.registeredAddress}
      </p>
    </DocPage>
  );
}
