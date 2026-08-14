import type { Metadata } from 'next';
import Link from 'next/link';

import { PlaceholderWarning } from '@/components/site/chrome';
import { siteConfig } from '@/lib/site-config';

export const metadata: Metadata = {
  title: 'Support',
  description:
    'Help with the Krishi Sech app — contact, common questions, permissions and account deletion.',
};

const FAQ = [
  {
    q: 'I am not receiving the sign-in code',
    a: 'Codes arrive by SMS and can take a minute. Check that the number you entered is the one on your account, that your phone has signal, and that the message has not gone to a spam or promotions folder. If you request codes repeatedly you will be rate-limited for a short while — wait a few minutes and try once more.',
  },
  {
    q: 'The weather is showing the wrong place',
    a: 'The app uses your location to pick the nearest place. If the permission is denied or the GPS fix is poor, set your district by hand from the location screen — you can always override the automatic choice.',
  },
  {
    q: 'I am not getting task reminders',
    a: 'Reminders need notification permission. Check it is granted in your phone settings, and that battery optimisation is not stopping the app from running in the background — on many Indian handsets this is the usual cause. Reminders are scheduled on the device, so they still work without a data connection.',
  },
  {
    q: 'The disease scan gave a diagnosis I do not agree with',
    a: 'The diagnosis is an automated best guess from a photograph, not a laboratory result, and it can be wrong. Take a clear, well-lit photo of the affected part alone for the best result — and confirm anything significant with a local expert before you spray or treat.',
  },
  {
    q: 'Can I change the app language?',
    a: 'Yes. The language selector is on the profile screen, and it changes every screen, reminder and assistant answer. The app ships 23 languages.',
  },
  {
    q: 'How do I delete my account?',
    a: 'From the deletion page on this site, or in the app under Profile → Delete account. It is immediate and permanent.',
  },
];

export default function SupportPage() {
  return (
    <main id="main" className="shell doc">
      <div className="glass panel stack doc__card">
        <PlaceholderWarning />

        <header className="stack" style={{ gap: '0.35rem' }}>
          <p className="eyebrow">We are here to help</p>
          <h1 className="h1 doc__title">Support</h1>
          <p className="lede">
            Questions about {siteConfig.appName}, a problem with the app, or a
            request about your data — this page covers the usual ones, and how to
            reach a person for the rest.
          </p>
        </header>

        <div className="grid grid--halves">
          <div className="glass glass--flat panel">
            <h2 className="h3">Email us</h2>
            <p className="muted support__body">
              The fastest route. Tell us your registered phone number, your
              phone model, and what you were doing when the problem happened.
            </p>
            <p className="support__contact">
              <a
                className="btn btn--primary"
                href={`mailto:${siteConfig.supportEmail}`}
              >
                {siteConfig.supportEmail}
              </a>
            </p>
          </div>

          <div className="glass glass--flat panel">
            <h2 className="h3">Delete your account</h2>
            <p className="muted support__body">
              You do not need to contact us to remove your data. You can do it
              yourself from the web, with no app install.
            </p>
            <p className="support__contact">
              <Link className="btn btn--glass" href="/delete-account">
                Go to account deletion
              </Link>
            </p>
          </div>
        </div>

        <div className="doc__body">
          <h2>Common questions</h2>
          <dl className="faq">
            {FAQ.map((item) => (
              <div key={item.q} className="faq__item">
                <dt>{item.q}</dt>
                <dd>{item.a}</dd>
              </div>
            ))}
          </dl>

          <h2>Permissions the app asks for</h2>
          <div className="table-scroll">
            <table className="doc__table">
              <thead>
                <tr>
                  <th scope="col">Permission</th>
                  <th scope="col">What it is used for</th>
                  <th scope="col">Required?</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <th scope="row">Location</th>
                  <td>Local weather and seasonal advice for your area.</td>
                  <td>No — you can set your district manually.</td>
                </tr>
                <tr>
                  <th scope="row">Camera and photos</th>
                  <td>Taking or choosing a crop photo for disease analysis.</td>
                  <td>No — only needed for the disease scan feature.</td>
                </tr>
                <tr>
                  <th scope="row">Notifications</th>
                  <td>Task reminders and announcements.</td>
                  <td>No — but reminders will not appear without it.</td>
                </tr>
              </tbody>
            </table>
          </div>

          <h2>Reporting a security problem</h2>
          <p>
            If you have found a vulnerability, please email{' '}
            <a href={`mailto:${siteConfig.supportEmail}`}>
              {siteConfig.supportEmail}
            </a>{' '}
            with the details rather than posting it publicly, and give us a
            reasonable chance to fix it. We will not pursue action against anyone
            who reports a genuine issue in good faith and does not access other
            farmers&apos; data.
          </p>

          <h2>Legal</h2>
          <p>
            <Link href="/privacy">Privacy Policy</Link> ·{' '}
            <Link href="/terms">Terms of Service</Link> ·{' '}
            <Link href="/data-safety">Data safety summary</Link>
          </p>
        </div>
      </div>
    </main>
  );
}
