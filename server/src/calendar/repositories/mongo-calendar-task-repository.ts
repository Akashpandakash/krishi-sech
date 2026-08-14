import type {
  CalendarTaskDocument,
  MongoDatabase,
} from '../../database/mongo-database.js';
import type {
  CalendarTaskInput,
  CalendarTaskRecord,
  CalendarTaskRepository,
} from './calendar-task-repository.js';

function toCalendarTaskRecord(
  document: CalendarTaskDocument,
): CalendarTaskRecord {
  const { _id, ...rest } = document;
  return { id: _id, ...rest };
}

export class MongoCalendarTaskRepository implements CalendarTaskRepository {
  constructor(private readonly database: MongoDatabase) {}

  async create(
    userId: string,
    input: CalendarTaskInput,
  ): Promise<CalendarTaskRecord> {
    const { id, ...rest } = input;
    const now = new Date();
    const document: CalendarTaskDocument = {
      ...rest,
      _id: id,
      userId,
      createdAt: now,
      updatedAt: now,
    };
    await this.database.calendarTasks.insertOne(document);
    return toCalendarTaskRecord(document);
  }

  async findAllByUser(userId: string): Promise<CalendarTaskRecord[]> {
    const documents = await this.database.calendarTasks
      .find({ userId })
      .sort({ dueDate: 1 })
      .toArray();
    return documents.map(toCalendarTaskRecord);
  }

  async findByIdAndUser(
    id: string,
    userId: string,
  ): Promise<CalendarTaskRecord | null> {
    const document = await this.database.calendarTasks.findOne({
      _id: id,
      userId,
    });
    return document ? toCalendarTaskRecord(document) : null;
  }

  async update(
    id: string,
    userId: string,
    input: Omit<CalendarTaskInput, 'id'>,
  ): Promise<CalendarTaskRecord> {
    const document = await this.database.calendarTasks.findOneAndUpdate(
      { _id: id, userId },
      { $set: { ...input, updatedAt: new Date() } },
      { returnDocument: 'after' },
    );
    if (!document) throw new Error('Calendar task not found');
    return toCalendarTaskRecord(document);
  }

  async delete(id: string, userId: string): Promise<void> {
    const result = await this.database.calendarTasks.deleteOne({
      _id: id,
      userId,
    });
    if (result.deletedCount === 0) throw new Error('Calendar task not found');
  }
}
