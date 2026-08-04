CREATE TABLE "fertilizer_recommendations" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "cropId" TEXT NOT NULL,
  "language" TEXT NOT NULL,
  "engineVersion" TEXT NOT NULL,
  "recommendedFertilizer" TEXT NOT NULL,
  "quantity" JSONB NOT NULL,
  "applicationMethod" TEXT NOT NULL,
  "bestApplicationTime" TEXT NOT NULL,
  "safetyPrecautions" JSONB NOT NULL,
  "organicAlternative" TEXT NOT NULL,
  "nextRecommendationDate" TIMESTAMP(3) NOT NULL,
  "confidence" DOUBLE PRECISION NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "fertilizer_recommendations_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "fertilizer_recommendations_userId_cropId_createdAt_idx"
  ON "fertilizer_recommendations"("userId", "cropId", "createdAt");
ALTER TABLE "fertilizer_recommendations" ADD CONSTRAINT "fertilizer_recommendations_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "fertilizer_recommendations" ADD CONSTRAINT "fertilizer_recommendations_cropId_fkey"
  FOREIGN KEY ("cropId") REFERENCES "crops"("id") ON DELETE CASCADE ON UPDATE CASCADE;
