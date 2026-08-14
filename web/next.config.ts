import type { NextConfig } from 'next';

/**
 * The admin panel talks to the Express API cross-origin, so every environment
 * must whitelist this app's exact origin in the backend's
 * CORS_ALLOWED_ORIGINS. The dev server runs on :4000 because the API already
 * owns :3000.
 */
const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  // Emits .next/standalone with only the traced runtime dependencies, which is
  // what the Dockerfile copies. `next start` is unaffected.
  output: 'standalone',
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'X-Frame-Options', value: 'DENY' },
        ],
      },
      {
        // The panel renders live farmer data and must never be cached by a
        // shared proxy or left in the back/forward cache of a shared desktop.
        source: '/admin/:path*',
        headers: [
          { key: 'Cache-Control', value: 'no-store, max-age=0' },
          { key: 'X-Robots-Tag', value: 'noindex, nofollow' },
        ],
      },
    ];
  },
};

export default nextConfig;
