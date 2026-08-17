export interface AuditLogEntry {
  id: string;
  adminId: string;
  adminEmail: string;
  action: string;
  targetType: string | null;
  targetId: string | null;
  summary: string;
  ipAddress: string | null;
  createdAt: Date;
}

export type AuditLogInput = Omit<AuditLogEntry, 'id' | 'createdAt'>;

export interface AuditLogRepository {
  record(input: AuditLogInput): Promise<void>;
  list(limit: number, action?: string): Promise<AuditLogEntry[]>;
}
