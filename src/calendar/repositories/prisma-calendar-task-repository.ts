import { PrismaClient } from '@prisma/client';

import type {
  CalendarTaskInput,
  CalendarTaskRecord,
  CalendarTaskRepository,
} from './calendar-task-repository.js';

export class PrismaCalendarTaskRepository implements CalendarTaskRepository {
  constructor(private readonly prisma: PrismaClient) {}

  create(userId: string, input: CalendarTaskInput): Promise<CalendarTaskRecord> {
    return this.prisma.calendarTask.create({ data: { ...input, userId } });
  }

  findAllByUser(userId: string): Promise<CalendarTaskRecord[]> {
    return this.prisma.calendarTask.findMany({
      where: { userId },
      orderBy: { dueDate: 'asc' },
    });
  }

  findByIdAndUser(id: string, userId: string): Promise<CalendarTaskRecord | null> {
    return this.prisma.calendarTask.findFirst({ where: { id, userId } });
  }

  update(
    id: string,
    userId: string,
    input: Omit<CalendarTaskInput, 'id'>,
  ): Promise<CalendarTaskRecord> {
    return this.prisma.calendarTask.update({
      where: { id, userId },
      data: input,
    });
  }

  async delete(id: string, userId: string): Promise<void> {
    await this.prisma.calendarTask.delete({ where: { id, userId } });
  }
}
