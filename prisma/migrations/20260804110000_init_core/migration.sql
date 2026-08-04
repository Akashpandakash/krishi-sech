CREATE TYPE "GrowthStage" AS ENUM (
  'sowing', 'germination', 'seedling', 'vegetative', 'flowering',
  'fruiting', 'maturity', 'harvested'
);
CREATE TYPE "LandUnit" AS ENUM ('acre', 'hectare', 'bigha', 'katha');
CREATE TYPE "SoilType" AS ENUM (
  'alluvial', 'black', 'red', 'laterite', 'sandy', 'clay', 'loamy', 'other'
);
CREATE TYPE "IrrigationMethod" AS ENUM (
  'drip', 'sprinkler', 'flood', 'rainFed', 'manual'
);
CREATE TYPE "CropHealthStatus" AS ENUM (
  'healthy', 'moderate', 'needsAttention'
);

CREATE TABLE "users" (
  "id" TEXT NOT NULL,
  "phone" TEXT NOT NULL,
  "name" TEXT,
  "preferredLanguage" TEXT NOT NULL DEFAULT 'bn',
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

CREATE TABLE "crops" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "cropName" TEXT NOT NULL,
  "variety" TEXT NOT NULL,
  "sowingDate" TIMESTAMP(3) NOT NULL,
  "growthStage" "GrowthStage" NOT NULL,
  "landArea" DOUBLE PRECISION NOT NULL,
  "landUnit" "LandUnit" NOT NULL,
  "soilType" "SoilType" NOT NULL,
  "irrigationMethod" "IrrigationMethod" NOT NULL,
  "expectedHarvestDate" TIMESTAMP(3),
  "healthStatus" "CropHealthStatus" NOT NULL DEFAULT 'healthy',
  "notes" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "crops_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "crops_userId_createdAt_idx" ON "crops"("userId", "createdAt");
ALTER TABLE "crops" ADD CONSTRAINT "crops_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE "calendar_tasks" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "cropId" TEXT NOT NULL,
  "taskType" TEXT NOT NULL,
  "dueDate" TIMESTAMP(3) NOT NULL,
  "status" TEXT NOT NULL,
  "notes" TEXT,
  "reminderEnabled" BOOLEAN NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "calendar_tasks_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "calendar_tasks_userId_dueDate_idx"
  ON "calendar_tasks"("userId", "dueDate");
CREATE INDEX "calendar_tasks_cropId_idx" ON "calendar_tasks"("cropId");
ALTER TABLE "calendar_tasks" ADD CONSTRAINT "calendar_tasks_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "calendar_tasks" ADD CONSTRAINT "calendar_tasks_cropId_fkey"
  FOREIGN KEY ("cropId") REFERENCES "crops"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE "otp_codes" (
  "id" TEXT NOT NULL,
  "phone" TEXT NOT NULL,
  "codeHash" TEXT NOT NULL,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "attempts" INTEGER NOT NULL DEFAULT 0,
  "consumedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "otp_codes_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "otp_codes_phone_createdAt_idx"
  ON "otp_codes"("phone", "createdAt");

CREATE TABLE "refresh_tokens" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "tokenHash" TEXT NOT NULL,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "revokedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "refresh_tokens_tokenHash_key"
  ON "refresh_tokens"("tokenHash");
CREATE INDEX "refresh_tokens_userId_revokedAt_idx"
  ON "refresh_tokens"("userId", "revokedAt");
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
