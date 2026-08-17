import '../../config/load-environment.js';

import { randomBytes } from 'node:crypto';

import { adminAuthService, adminRepository, mongoDatabase } from '../../composition.js';
import { adminRoles, type AdminRole } from '../repositories/admin-repository.js';

interface Arguments {
  email?: string;
  name?: string;
  password?: string;
  role?: string;
}

function parseArguments(argv: string[]): Arguments {
  const parsed: Arguments = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index]!;
    if (!token.startsWith('--')) continue;
    const [flag, inlineValue] = token.slice(2).split('=');
    const value = inlineValue ?? argv[++index];
    if (!flag || value === undefined) continue;
    if (flag === 'email') parsed.email = value;
    if (flag === 'name') parsed.name = value;
    if (flag === 'password') parsed.password = value;
    if (flag === 'role') parsed.role = value;
  }
  return parsed;
}

/** Meets the admin password policy without a human having to invent one. */
function generatePassword(): string {
  const alphabet =
    'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  const bytes = randomBytes(18);
  const core = [...bytes].map((byte) => alphabet[byte % alphabet.length]).join('');
  return `Ks9!${core}`;
}

async function main(): Promise<void> {
  const args = parseArguments(process.argv.slice(2));
  const email = args.email?.trim();
  if (!email) {
    console.error(
      'Usage: npm run admin:create -- --email <email> [--name <name>] [--role owner|admin|analyst] [--password <password>]',
    );
    process.exitCode = 1;
    return;
  }
  const role = (args.role?.trim() || 'owner') as AdminRole;
  if (!adminRoles.includes(role)) {
    console.error(`--role must be one of: ${adminRoles.join(', ')}`);
    process.exitCode = 1;
    return;
  }
  if (!mongoDatabase) {
    console.warn(
      'MONGODB_URI is not set: this admin will live in memory and disappear when the process exits.',
    );
  }

  const existingAdmins = await adminRepository.countAdmins();
  const password = args.password?.trim() || generatePassword();
  const admin = await adminAuthService.createAdmin({
    email,
    name: args.name?.trim() || email.split('@')[0]!,
    password,
    role,
  });

  console.log('');
  console.log('Admin created');
  console.log(`  email    ${admin.email}`);
  console.log(`  name     ${admin.name}`);
  console.log(`  role     ${admin.role}`);
  if (!args.password) {
    console.log(`  password ${password}`);
    console.log('');
    console.log('Store this password now — it is not shown again.');
  }
  if (existingAdmins === 0) {
    console.log('');
    console.log('Sign in at /admin/ on the website with these credentials.');
  }
}

main()
  .catch((error: unknown) => {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoDatabase?.close();
  });
