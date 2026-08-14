import type { Metadata, Viewport } from 'next';

import './globals.css';

export const metadata: Metadata = {
  title: {
    default: 'Krishi Sech',
    template: '%s · Krishi Sech',
  },
  description:
    'Krishi Sech is a smart agriculture platform for farmers, agricultural experts and the farm marketplace.',
};

export const viewport: Viewport = {
  // Single value, because the page is pinned to light regardless of the OS
  // setting — offering a dark browser chrome colour would mismatch the page.
  themeColor: '#f7faf7',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // `data-theme="light"` pins the page to light, matching the Flutter app's
  // ThemeMode.light. The dark token set is complete and validated — remove the
  // attribute to re-enable system-preference theming.
  return (
    <html lang="en" data-theme="light">
      <body>
        {/* The field every glass surface refracts. Decorative only. */}
        <div className="aurora" aria-hidden="true" />
        {children}
      </body>
    </html>
  );
}
