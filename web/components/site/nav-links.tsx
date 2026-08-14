'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

import { SITE_NAV } from '@/lib/site-config';

/** Client-only so the current page can be marked. Everything else in the
 *  header and footer stays a server component. */
export function NavLinks() {
  const pathname = usePathname();

  return (
    <ul className="site-links">
      {SITE_NAV.slice(1).map((item) => {
        const active = pathname === item.href;
        return (
          <li key={item.href}>
            <Link
              className="site-link"
              href={item.href}
              aria-current={active ? 'page' : undefined}
            >
              {item.label}
            </Link>
          </li>
        );
      })}
      <li>
        <Link className="btn btn--primary btn--sm site-cta" href="/admin">
          Admin
        </Link>
      </li>
    </ul>
  );
}
