ALTER TABLE "users"
ADD COLUMN "profilePhotoUrl" TEXT,
ADD COLUMN "state" TEXT,
ADD COLUMN "district" TEXT,
ADD COLUMN "village" TEXT;

CREATE TABLE "farm_profiles" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "farmName" TEXT NOT NULL,
  "farmerType" TEXT NOT NULL,
  "totalLandArea" DOUBLE PRECISION NOT NULL,
  "landUnit" TEXT NOT NULL,
  "soilType" TEXT NOT NULL,
  "irrigationSource" TEXT NOT NULL,
  "mainCrops" TEXT[],
  "coarseLocation" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "farm_profiles_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "farm_profiles_userId_key" ON "farm_profiles"("userId");
ALTER TABLE "farm_profiles" ADD CONSTRAINT "farm_profiles_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
