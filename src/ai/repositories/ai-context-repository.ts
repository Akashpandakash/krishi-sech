export interface AiLocationContext {
  city: string;
  district: string;
  state: string;
  country: string;
  latitude: number | null;
  longitude: number | null;
}

export interface AiWeatherContext {
  temperatureCelsius: number;
  condition: string;
  humidityPercent: number;
  windSpeedKmh: number;
  rainProbabilityPercent: number | null;
  updatedAt: Date;
}

export interface AiTaskContext {
  id: string;
  cropId: string;
  title: string;
  taskType: string;
  dueAt: Date;
}

export interface AiActivityContext {
  cropId: string;
  occurredAt: Date;
  details: string | null;
}

export interface AiDiseaseScanContext {
  scanId: string;
  cropId: string;
  possibleDisease: string;
  confidence: number;
  severity: string;
  createdAt: Date;
}

/** Sources that will be backed by their feature repositories as those backend
 * modules are introduced. The context engine remains independent of storage. */
export interface AiContextRepository {
  findLocation(userId: string): Promise<AiLocationContext | null>;
  findCurrentWeather(userId: string): Promise<AiWeatherContext | null>;
  findUpcomingTasks(userId: string): Promise<AiTaskContext[]>;
  findLastIrrigation(userId: string): Promise<AiActivityContext | null>;
  findLastFertilizer(userId: string): Promise<AiActivityContext | null>;
  findRecentDiseaseScans(userId: string): Promise<AiDiseaseScanContext[]>;
}
