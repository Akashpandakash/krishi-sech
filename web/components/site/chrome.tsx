import Image from 'next/image';
import Link from 'next/link';

import { NavLinks } from './nav-links';
import { hasPlaceholders, siteConfig } from '@/lib/site-config';

export function SiteHeader() {
  return (
    <header className="site-header">
      <div className="shell glass glass--strong site-nav">
        <Link className="site-brand" href="/">
          <Image
            src="/logo.png"
            alt=""
            width={40}
            height={40}
            className="site-brand__mark"
            priority
          />
          <span className="site-brand__text">
            <strong>{siteConfig.appName}</strong>
            <small>Smart agriculture</small>
          </span>
        </Link>
        <nav aria-label="Primary">
          <NavLinks />
        </nav>
      </div>
    </header>
  );
}

const FOOTER_GROUPS = [
  {
    heading: 'Product',
    links: [
      { href: '/', label: 'Home' },
      { href: '/#features', label: 'Features' },
      { href: '/#languages', label: 'Languages' },
    ],
  },
  {
    heading: 'Legal',
    links: [
      { href: '/privacy', label: 'Privacy Policy' },
      { href: '/terms', label: 'Terms of Service' },
      { href: '/data-safety', label: 'Data safety' },
    ],
  },
  {
    heading: 'Help',
    links: [
      { href: '/support', label: 'Support' },
      { href: '/delete-account', label: 'Delete account' },
      { href: '/admin', label: 'Admin panel' },
    ],
  },
];

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="shell">
        <div className="site-footer__top">
          <div className="site-footer__brand">
            <Link className="site-brand" href="/">
              <Image
                src="/logo.png"
                alt=""
                width={40}
                height={40}
                className="site-brand__mark"
              />
              <span className="site-brand__text">
                <strong>{siteConfig.appName}</strong>
                <small>Smart agriculture</small>
              </span>
            </Link>
            <p className="muted site-footer__blurb">
              A farm assistant for Indian farmers — crop calendar, weather,
              disease scanning and irrigation advice, in 23 languages.
            </p>
            <p className="site-footer__contact">
              <a href={`mailto:${siteConfig.supportEmail}`}>
                {siteConfig.supportEmail}
              </a>
            </p>
          </div>

          {FOOTER_GROUPS.map((group) => (
            <nav key={group.heading} aria-label={group.heading}>
              <p className="eyebrow site-footer__heading">{group.heading}</p>
              <ul className="site-footer__list">
                {group.links.map((link) => (
                  <li key={link.href}>
                    <Link href={link.href}>{link.label}</Link>
                  </li>
                ))}
              </ul>
            </nav>
          ))}
        </div>

        <div className="site-footer__bottom">
          <p className="muted">
            © {new Date().getFullYear()} {siteConfig.legalEntity}. Operated from{' '}
            {siteConfig.registeredAddress}.
          </p>
          <p className="muted">Made for farmers in India 🌱</p>
        </div>
      </div>
    </footer>
  );
}

/**
 * Shown at the top of every legal page while `site-config.ts` still holds
 * template values. Better a visible warning during development than a policy
 * that reads as finished and gets the listing rejected.
 */
export function PlaceholderWarning() {
  if (!hasPlaceholders) return null;
  return (
    <p className="notice notice--error" role="alert">
      <strong>Not ready to publish.</strong> This page still contains
      placeholder company and contact details. Fill in{' '}
      <code>web/lib/site-config.ts</code> before submitting to Google Play.
    </p>
  );
}

/** Wrapper for the long-form legal pages. */
export function DocPage({
  title,
  updated,
  intro,
  children,
}: {
  title: string;
  updated: string;
  intro?: string;
  children: React.ReactNode;
}) {
  return (
    <main id="main" className="shell doc">
      <div className="glass panel stack doc__card">
        <PlaceholderWarning />
        <header className="stack" style={{ gap: '0.35rem' }}>
          <p className="eyebrow">Last updated {updated}</p>
          <h1 className="h1 doc__title">{title}</h1>
          {intro ? <p className="lede">{intro}</p> : null}
        </header>
        <div className="doc__body">{children}</div>
      </div>
    </main>
  );
}
