import type { Metadata } from 'next';
import Link from 'next/link';

import { DocPage } from '@/components/site/chrome';
import { siteConfig } from '@/lib/site-config';

export const metadata: Metadata = {
  title: 'Terms of Service',
  description:
    'The terms you agree to when you use the Krishi Sech app and website.',
};

export default function TermsPage() {
  return (
    <DocPage
      title="Terms of Service"
      updated={siteConfig.termsLastUpdated}
      intro={`These terms are the agreement between you and ${siteConfig.legalEntity}, the operator of ${siteConfig.appName}, for use of the app and this website. By creating an account you accept them.`}
    >
      <h2>Who can use {siteConfig.appName}</h2>
      <p>
        You must be at least 18 years old, or the age of majority where you live,
        and able to enter into a contract. The service is offered for managing
        farmland and agricultural activity.
      </p>

      <h2>Your account</h2>
      <p>
        Your account is identified by your phone number, or by the Google account
        you sign in with. Keep access to that number secure — anyone who receives
        the one-time code can reach your account. Tell us promptly at{' '}
        <a href={`mailto:${siteConfig.supportEmail}`}>{siteConfig.supportEmail}</a>{' '}
        if you believe someone else has access.
      </p>
      <p>
        One account is for one person. Do not share it, sell it, or create
        accounts using someone else’s number.
      </p>

      <h2>Agricultural advice is guidance, not a guarantee</h2>
      <p>
        This is the most important term in this document, so it is stated plainly.
      </p>
      <p>
        {siteConfig.appName} produces weather forecasts, disease diagnoses from
        photographs, fertilizer and irrigation recommendations, seasonal advice
        and answers from an automated assistant. All of it is{' '}
        <strong>informational guidance generated automatically</strong>, much of
        it by AI systems that can be confidently wrong. It is not a substitute
        for a qualified agronomist, an agricultural extension officer, a soil
        test, or your own judgement and knowledge of your land.
      </p>
      <ul>
        <li>
          A disease diagnosis from a photograph is a probable identification, not
          a laboratory result.
        </li>
        <li>
          Fertilizer and irrigation quantities are estimates from the details you
          entered. Verify them before applying anything, and follow the label and
          local regulations for any agrochemical.
        </li>
        <li>
          Weather forecasts come from a third-party model and can be wrong,
          delayed or unavailable.
        </li>
      </ul>
      <p>
        Decisions about your crop remain yours. Before acting on anything
        significant — spraying, applying fertilizer, changing an irrigation
        schedule, or timing a harvest — confirm it with a qualified local expert.
      </p>

      <h2>What you may not do</h2>
      <ul>
        <li>Use the service unlawfully, or to break agricultural regulations.</li>
        <li>
          Upload photographs or content that is not yours to share, or that
          contains other people’s personal information.
        </li>
        <li>
          Attempt to breach, overload, scrape or reverse-engineer the service, or
          access another farmer’s data.
        </li>
        <li>
          Resell or redistribute the advice as your own commercial advisory
          service.
        </li>
      </ul>

      <h2>Your content</h2>
      <p>
        The farm details, crops, tasks and photographs you enter remain yours. You
        grant us only the permission needed to run the service for you: to store
        your records, and to send a photograph to our AI provider to produce a
        diagnosis. We do not claim ownership and we do not use your content to
        train models.
      </p>

      <h2>Availability</h2>
      <p>
        We aim to keep the service running but do not promise uninterrupted
        availability. Features may change or be withdrawn, and the service depends
        on third parties — SMS delivery, weather data, AI providers — whose
        outages will affect it. Reminders depend on your device and its
        notification settings; do not rely on {siteConfig.appName} as your only
        reminder for a time-critical operation.
      </p>

      <h2>Cost</h2>
      <p>
        The service is currently provided free of charge. If paid features are
        introduced, the price and terms will be shown before you are asked to pay,
        and nothing you already have will start charging without your agreement.
      </p>

      <h2>Ending your use</h2>
      <p>
        You may stop at any time and delete your account from{' '}
        <Link href="/delete-account">the deletion page</Link> or from within the
        app. We may suspend or close an account that breaches these terms, is used
        fraudulently, or is used to harm other users or the service. Where
        practical we will tell you why.
      </p>

      <h2>Liability</h2>
      <p>
        To the extent the law allows, {siteConfig.legalEntity} is not liable for
        crop loss, yield reduction, wasted inputs, lost profit or other indirect
        loss arising from reliance on advice generated by the service. Nothing in
        these terms limits liability that cannot lawfully be limited, including
        for death or personal injury caused by negligence, or for fraud.
      </p>

      <h2>Changes to these terms</h2>
      <p>
        We may update these terms as the service changes. The date at the top
        shows the current version, and material changes will be announced in the
        app. Continuing to use {siteConfig.appName} after a change means you
        accept the updated terms.
      </p>

      <h2>Governing law</h2>
      <p>
        These terms are governed by the laws of India, and disputes are subject to{' '}
        {siteConfig.jurisdiction}.
      </p>

      <h2>Contact</h2>
      <p>
        {siteConfig.legalEntity}
        <br />
        {siteConfig.registeredAddress}
        <br />
        <a href={`mailto:${siteConfig.supportEmail}`}>{siteConfig.supportEmail}</a>
      </p>
    </DocPage>
  );
}
