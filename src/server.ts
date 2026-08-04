import './config/load-environment.js';

import { app, prisma } from './app.js';
import { loadAppConfig } from './config/app-config.js';

const appConfig = loadAppConfig();
const port = Number.parseInt(process.env.PORT ?? '3000', 10);
const host = process.env.HOST ?? '0.0.0.0';

const server = app.listen(port, host, () => {
  if (appConfig.loggingEnabled) {
    console.log(`Krishi Sech backend listening on ${host}:${port}`);
  }
});

let shuttingDown = false;

function shutdown(): void {
  if (shuttingDown) return;
  shuttingDown = true;
  const forceShutdown = setTimeout(() => process.exit(1), 25_000);
  forceShutdown.unref();
  server.close(async (error) => {
    try {
      await prisma.$disconnect();
    } finally {
      clearTimeout(forceShutdown);
      process.exitCode = error ? 1 : 0;
    }
  });
}

process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);
