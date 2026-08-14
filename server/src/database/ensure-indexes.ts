import '../config/load-environment.js';

import { MongoDatabase } from './mongo-database.js';

async function main(): Promise<void> {
  const uri = process.env.MONGODB_URI?.trim();
  if (!uri) {
    console.error('MONGODB_URI is required to create indexes');
    process.exitCode = 1;
    return;
  }
  const database = new MongoDatabase(uri, process.env.MONGODB_DB_NAME);
  try {
    await database.ensureIndexes();
    console.log('MongoDB indexes are up to date');
  } finally {
    await database.close();
  }
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
