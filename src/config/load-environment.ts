import { config as loadDotEnv } from 'dotenv';

// Preserve shell/container values, then fill gaps from the existing local
// secret file and the selected environment-specific file.
loadDotEnv({ path: '.env', override: false, quiet: true });
const environment = process.env.APP_ENV?.trim() || 'development';
loadDotEnv({
  path: `.env.${environment}`,
  override: false,
  quiet: true,
});
