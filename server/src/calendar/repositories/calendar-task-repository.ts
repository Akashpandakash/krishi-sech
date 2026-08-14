export const calendarTaskTypes = [
  'irrigation',
  'fertilizer',
  'pestInspection',
  'harvest',
] as const;
export const calendarTaskStatuses = ['pending', 'completed'] as const;

export interface CalendarTaskInput {
  id: string;
  cropId: string;
  taskType: string;
  dueDate: Date;
  status: string;
  notes: string | null;
  reminderEnabled: boolean;
}

export interface CalendarTaskRecord extends CalendarTaskInput {
  userId: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface CalendarTaskRepository {
  create(userId: string, input: CalendarTaskInput): Promise<CalendarTaskRecord>;
  findAllByUser(userId: string): Promise<CalendarTaskRecord[]>;
  findByIdAndUser(id: string, userId: string): Promise<CalendarTaskRecord | null>;
  update(
    id: string,
    userId: string,
    input: Omit<CalendarTaskInput, 'id'>,
  ): Promise<CalendarTaskRecord>;
  delete(id: string, userId: string): Promise<void>;
}
