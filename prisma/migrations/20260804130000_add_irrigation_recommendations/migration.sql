CREATE TABLE "irrigation_recommendations" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "cropId" TEXT NOT NULL,
  "language" TEXT NOT NULL,
  "landType" TEXT NOT NULL,
  "engineVersion" TEXT NOT NULL,
  "irrigationRequired" BOOLEAN NOT NULL,
  "waterQuantity" JSONB NOT NULL,
  "bestIrrigationTime" TEXT NOT NULL,
  "irrigationMethod" TEXT NOT NULL,
  "nextIrrigationDate" TIMESTAMP(3) NOT NULL,
  "confidence" DOUBLE PRECISION NOT NULL,
  "reasoning" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "irrigation_recommendations_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "irrigation_recommendations_userId_cropId_createdAt_idx"
  ON "irrigation_recommendations"("userId", "cropId", "createdAt");
ALTER TABLE "irrigation_recommendations" ADD CONSTRAINT "irrigation_recommendations_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "irrigation_recommendations" ADD CONSTRAINT "irrigation_recommendations_cropId_fkey"
  FOREIGN KEY ("cropId") REFERENCES "crops"("id") ON DELETE CASCADE ON UPDATE CASCADE;
