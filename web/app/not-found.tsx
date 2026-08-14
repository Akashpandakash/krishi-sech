import Link from 'next/link';

import { SiteFooter, SiteHeader } from '@/components/site/chrome';

export const metadata = {
  title: 'Page not found',
};

export default function NotFound() {
  return (
    <>
      <SiteHeader />
      <main id="main" className="shell section notfound">
        <div className="glass glass--strong panel stack notfound__card">
          <p className="eyebrow">Error 404</p>
          <h1 className="h1">This page has not sprouted.</h1>
          <p className="lede">
            The address you followed does not exist. It may have moved, or the
            link may have been mistyped.
          </p>
          <div className="row">
            <Link className="btn btn--primary" href="/">
              Back to home
            </Link>
            <Link className="btn btn--glass" href="/support">
              Get support
            </Link>
          </div>
        </div>
      </main>
      <SiteFooter />
    </>
  );
}
