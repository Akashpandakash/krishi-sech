import type { Metadata } from 'next';

import { AuthProvider } from '@/components/admin/auth-context';
import { AdminShell } from '@/components/admin/shell';

export const metadata: Metadata = {
  title: 'Admin',
  robots: { index: false, follow: false },
};

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthProvider>
      <AdminShell>{children}</AdminShell>
    </AuthProvider>
  );
}
