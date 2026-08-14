import Image from 'next/image';
import Link from 'next/link';

import { siteConfig } from '@/lib/site-config';

const FEATURES = [
  {
    title: 'A crop calendar that nudges',
    body: 'Every crop gets a task schedule — sowing, irrigation, fertilizer, harvest — with reminders that arrive on the farmer’s phone in their own language.',
  },
  {
    title: 'Weather where the field is',
    body: 'Forecasts resolved to the farm’s area, with seasonal advice that reacts to what the coming week actually looks like.',
  },
  {
    title: 'Disease scanning from a photo',
    body: 'A picture of an affected leaf comes back with a likely diagnosis and a treatment plan, so a problem is caught while it is still small.',
  },
  {
    title: 'Fertilizer and irrigation advice',
    body: 'Recommendations derived from the farm’s soil type, land area, irrigation source and the crop’s current growth stage.',
  },
  {
    title: 'An assistant that speaks the language',
    body: 'Ask a question and get an answer that already knows the farm’s crops, location and season — in the language the farmer reads.',
  },
  {
    title: 'Useful on a modest phone',
    body: 'Data is cached on the device, so the app stays usable when the signal drops and syncs again when it returns.',
  },
];

/** The 23 locales the app actually ships translations for. */
const LANGUAGES = [
  'অসমীয়া',
  'বাংলা',
  "बर' राव",
  'डोगरी',
  'ગુજરાતી',
  'हिन्दी',
  'ಕನ್ನಡ',
  'کٲشُر',
  'कोंकणी',
  'मैथिली',
  'മലയാളം',
  'ꯃꯤꯇꯩ ꯂꯣꯟ',
  'मराठी',
  'नेपाली',
  'ଓଡ଼ିଆ',
  'ਪੰਜਾਬੀ',
  'संस्कृतम्',
  'ᱥᱟᱱᱛᱟᱲᱤ',
  'سنڌي',
  'தமிழ்',
  'తెలుగు',
  'اردو',
  'English',
];

export default function HomePage() {
  return (
    <main id="main">
      <section className="shell hero">
        <div className="hero__copy">
          <p className="eyebrow">Smart agriculture, in the farmer’s language</p>
          <h1 className="h1">Every field deserves an agronomist in its pocket.</h1>
          <p className="lede">
            {siteConfig.appName} turns a smartphone into a farm assistant — a
            crop calendar that reminds, weather that matters, disease scanning
            from a photo, and irrigation and fertilizer advice grounded in the
            farm’s own soil and season.
          </p>
          <div className="row hero__actions">
            <a className="btn btn--primary" href="#features">
              See what it does
            </a>
            <Link className="btn btn--glass" href="/support">
              Get support
            </Link>
          </div>
        </div>

        <div className="hero__media">
          <Image
            src="/farmland.jpg"
            alt="Farmland at the start of the growing season"
            width={1400}
            height={663}
            className="hero__photo"
            priority
          />
          <div className="glass glass--strong hero__card">
            <p className="eyebrow">This week on the farm</p>
            <ul className="stack hero__tasks">
              <li className="spread">
                <span>Irrigate — Wheat, Plot 2</span>
                <span className="badge badge--warning" data-glyph="▲">
                  Due today
                </span>
              </li>
              <li className="spread">
                <span>Top dressing — Rice, Plot 1</span>
                <span className="badge badge--neutral">In 3 days</span>
              </li>
              <li className="spread">
                <span>Leaf scan — Tomato</span>
                <span className="badge badge--good" data-glyph="●">
                  Healthy
                </span>
              </li>
            </ul>
          </div>
        </div>
      </section>

      <section className="shell section" id="features">
        <h2 className="h2">What a farmer gets</h2>
        <div className="grid grid--halves section__grid">
          {FEATURES.map((feature) => (
            <article key={feature.title} className="glass panel">
              <h3 className="h3">{feature.title}</h3>
              <p className="muted feature__body">{feature.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="shell section" id="languages">
        <div className="glass panel stack">
          <div>
            <h2 className="h2">Built to be read, not translated</h2>
            <p className="lede section__lede">
              Every screen, every reminder and every answer from the assistant is
              available in {LANGUAGES.length} languages.
            </p>
          </div>
          <ul className="row language-list">
            {LANGUAGES.map((language) => (
              <li key={language} className="badge badge--neutral">
                {language}
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="shell section">
        <div className="glass glass--strong panel stack cta">
          <h2 className="h2">Questions, or need your data removed?</h2>
          <p className="lede">
            Support answers questions about the app, and you can delete your
            account and every record attached to it from the web — no app
            install required.
          </p>
          <div className="row cta__actions">
            <Link className="btn btn--primary" href="/support">
              Contact support
            </Link>
            <Link className="btn btn--glass" href="/delete-account">
              Delete my account
            </Link>
          </div>
        </div>
      </section>
    </main>
  );
}
