import type {
  CalendarTaskInput,
  CalendarTaskRecord,
  CalendarTaskRepository,
} from "./calendar-task-repository.js";

export class InMemoryCalendarTaskRepository implements CalendarTaskRepository {
  private readonly tasks = new Map<string, CalendarTaskRecord>();

  async create(
    userId: string,
    input: CalendarTaskInput,
  ): Promise<CalendarTaskRecord> {
    const now = new Date();
    const task = { ...input, userId, createdAt: now, updatedAt: now };
    this.tasks.set(task.id, task);
    return task;
  }

  async findAllByUser(userId: string): Promise<CalendarTaskRecord[]> {
    return [...this.tasks.values()]
      .filter((task) => task.userId === userId)
      .sort((left, right) => left.dueDate.getTime() - right.dueDate.getTime());
  }

  async findByIdAndUser(
    id: string,
    userId: string,
  ): Promise<CalendarTaskRecord | null> {
    const task = this.tasks.get(id);
    return task?.userId === userId ? task : null;
  }

  async update(
    id: string,
    userId: string,
    input: Omit<CalendarTaskInput, "id">,
  ): Promise<CalendarTaskRecord> {
    const existing = await this.findByIdAndUser(id, userId);
    if (existing == null) throw new Error("Calendar task not found");
    const task = { ...existing, ...input, updatedAt: new Date() };
    this.tasks.set(id, task);
    return task;
  }

  async delete(id: string, userId: string): Promise<void> {
    const existing = await this.findByIdAndUser(id, userId);
    if (existing == null) throw new Error("Calendar task not found");
    this.tasks.delete(id);
  }
}
