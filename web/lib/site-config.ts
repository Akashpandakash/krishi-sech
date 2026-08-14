/**
 * Site-wide identity and contact details.
 *
 * ┌──────────────────────────────────────────────────────────────────────┐
 * │  FILL IN THE THREE VALUES IN `owner` BELOW BEFORE SUBMITTING TO PLAY. │
 * │  Everything else on the legal pages is derived from them.             │
 * └──────────────────────────────────────────────────────────────────────┘
 *
 * A privacy policy or account-deletion page carrying a fake operator name or
 * an unreachable contact address is a Play listing rejection, and in most
 * jurisdictions is not a valid privacy notice at all. Until these are real,
 * every legal page renders a visible "not ready to publish" banner.
 */

const owner = {
  /**
   * The party named as data controller on the legal pages.
   *
   * TODO (before Play submission): this is currently the product's trading
   * name, used as a stand-in. A trading name is not a legal person, and a
   * privacy notice needs to identify the actual operator — the proprietor's
   * full name, or the registered company name — so that a farmer knows who
   * holds their data and who to bring a complaint against. Replace with the
   * real operator name once it is settled.
   */
  operatorName: 'Krishi Sech',

  /**
   * A dedicated, monitored mailbox. Play publishes it on the store listing and
   * farmers use it to reach you about their data, so it must actually be read.
   */
  supportEmail: 'support@krishisech.com',

  /**
   * City and state only — enough to identify where the operator is based
   * without publishing a home address. Also sets the governing jurisdiction.
   */
  city: 'Kolkata',
  state: 'West Bengal',
} as const;

export const siteConfig = {
  appName: 'Krishi Sech',

  /** The party that operates the service and controls the data. */
  legalEntity: owner.operatorName,

  /** Shown as the controller's location on the privacy and terms pages. */
  registeredAddress: `${owner.city}, ${owner.state}, India`,

  supportEmail: owner.supportEmail,
  /** One monitored mailbox handles both support and privacy requests. */
  privacyEmail: owner.supportEmail,

  /** Governing law for the terms, derived from where the operator is based. */
  jurisdiction: `the courts of ${owner.city}, ${owner.state}`,

  /** Play package identifier, used for store links. */
  packageName: 'com.krishisech.app',

  /** Dates shown on the legal pages. Update when the text materially changes. */
  policyLastUpdated: '14 August 2026',
  termsLastUpdated: '14 August 2026',
} as const;

/**
 * True while any template value survives, so the pages can warn loudly instead
 * of shipping a policy that reads as finished. Checks the raw `owner` inputs
 * rather than the derived strings — a placeholder city would otherwise hide
 * inside an address that looks superficially complete.
 */
export const hasPlaceholders = Object.values(owner).some((value) =>
  value.includes('PLACEHOLDER'),
);

export const SITE_NAV = [
  { href: '/', label: 'Home' },
  { href: '/support', label: 'Support' },
  { href: '/privacy', label: 'Privacy' },
  { href: '/terms', label: 'Terms' },
  { href: '/delete-account', label: 'Delete account' },
] as const;
