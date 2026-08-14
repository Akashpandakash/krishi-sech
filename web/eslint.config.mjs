import next from 'eslint-config-next';

/** eslint-config-next 16 ships a native flat config array, so it is spread
 *  directly — FlatCompat is only needed for the legacy eslintrc format. */
const config = [
  { ignores: ['.next/**', 'node_modules/**', 'next-env.d.ts'] },
  ...next,
];

export default config;
