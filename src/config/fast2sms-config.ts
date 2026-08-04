export interface Fast2SmsConfig {
  apiKey: string;
  senderId: string;
  route: string;
  requestTimeoutMs: number;
}

type EnvironmentValues = Record<string, string | undefined>;

export function loadFast2SmsConfig(
  values: EnvironmentValues = process.env,
  requestTimeoutMs = 20_000,
): Fast2SmsConfig {
  const required = (name: string): string => {
    const value = values[name]?.trim();
    if (!value) throw new Error(`${name} is required outside development`);
    return value;
  };

  const senderId = required('FAST2SMS_SENDER_ID');
  if (!/^[A-Za-z0-9]{3,6}$/.test(senderId)) {
    throw new Error('FAST2SMS_SENDER_ID has an invalid format');
  }
  const route = required('FAST2SMS_ROUTE');
  if (!/^[A-Za-z0-9_-]{1,32}$/.test(route)) {
    throw new Error('FAST2SMS_ROUTE has an invalid format');
  }

  return {
    apiKey: required('FAST2SMS_API_KEY'),
    senderId,
    route,
    requestTimeoutMs,
  };
}
