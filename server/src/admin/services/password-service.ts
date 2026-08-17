import {
  randomBytes,
  scrypt as scryptCallback,
  timingSafeEqual,
} from 'node:crypto';
import { promisify } from 'node:util';

interface ScryptParameters {
  N: number;
  r: number;
  p: number;
}

const scrypt = promisify(scryptCallback) as (
  password: string,
  salt: Buffer,
  keylen: number,
  options: ScryptParameters & { maxmem: number },
) => Promise<Buffer>;

/** OWASP-recommended scrypt parameters (2^16 cost, 8 block, 1 parallel). */
const parameters: ScryptParameters = { N: 65_536, r: 8, p: 1 };
const keyLength = 64;

/**
 * Node caps scrypt memory at 32 MB by default, which is below what N=65536
 * needs (128 * N * r = 64 MB), so the budget is derived from the parameters.
 */
function memoryLimit(options: ScryptParameters): number {
  return 128 * options.N * options.r * 2;
}

/** scrypt requires N to be a power of two above 1, and rejects anything else. */
function areParametersUsable(options: ScryptParameters): boolean {
  return (
    Number.isInteger(options.N) &&
    options.N >= 2 &&
    (options.N & (options.N - 1)) === 0 &&
    Number.isInteger(options.r) &&
    options.r >= 1 &&
    Number.isInteger(options.p) &&
    options.p >= 1 &&
    memoryLimit(options) <= 512 * 1024 * 1024
  );
}

/**
 * Encodes as `scrypt$N$r$p$salt$hash` so parameters can be raised later
 * without invalidating existing hashes.
 */
export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16);
  const derived = await scrypt(password, salt, keyLength, {
    ...parameters,
    maxmem: memoryLimit(parameters),
  });
  return [
    'scrypt',
    parameters.N,
    parameters.r,
    parameters.p,
    salt.toString('base64'),
    derived.toString('base64'),
  ].join('$');
}

export async function verifyPassword(
  password: string,
  encoded: string,
): Promise<boolean> {
  const parts = encoded.split('$');
  if (parts.length !== 6 || parts[0] !== 'scrypt') return false;
  const [, rawN, rawR, rawP, rawSalt, rawHash] = parts;
  const options = {
    N: Number.parseInt(rawN!, 10),
    r: Number.parseInt(rawR!, 10),
    p: Number.parseInt(rawP!, 10),
  };
  if (!areParametersUsable(options)) return false;
  const expected = Buffer.from(rawHash!, 'base64');
  if (expected.length === 0) return false;
  let derived: Buffer;
  try {
    derived = await scrypt(
      password,
      Buffer.from(rawSalt!, 'base64'),
      expected.length,
      { ...options, maxmem: memoryLimit(options) },
    );
  } catch {
    // A stored hash with parameters this build cannot compute is unusable,
    // which is a failed verification rather than a server error.
    return false;
  }
  return derived.length === expected.length && timingSafeEqual(derived, expected);
}

export interface PasswordPolicyIssue {
  code: string;
  message: string;
}

/** Admin accounts guard every farmer record, so the bar is higher than the app. */
export function checkPasswordPolicy(password: string): PasswordPolicyIssue[] {
  const issues: PasswordPolicyIssue[] = [];
  if (password.length < 12) {
    issues.push({
      code: 'TOO_SHORT',
      message: 'Password must be at least 12 characters',
    });
  }
  if (!/[a-z]/.test(password) || !/[A-Z]/.test(password)) {
    issues.push({
      code: 'MISSING_CASE',
      message: 'Password must mix uppercase and lowercase letters',
    });
  }
  if (!/\d/.test(password)) {
    issues.push({
      code: 'MISSING_DIGIT',
      message: 'Password must contain a number',
    });
  }
  if (!/[^A-Za-z0-9]/.test(password)) {
    issues.push({
      code: 'MISSING_SYMBOL',
      message: 'Password must contain a symbol',
    });
  }
  return issues;
}
