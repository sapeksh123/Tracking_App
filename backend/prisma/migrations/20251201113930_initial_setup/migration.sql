-- CreateTable
CREATE TABLE "Admin" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "name" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Admin_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'user',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "androidId" TEXT,
    "deviceModel" TEXT,
    "trackingConsent" BOOLEAN NOT NULL DEFAULT false,
    "consentedAt" TIMESTAMP(3),
    "lastSeen" TIMESTAMP(3),
    "isPunchedIn" BOOLEAN NOT NULL DEFAULT false,
    "currentSession" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Location" (
    "id" SERIAL NOT NULL,
    "userId" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "accuracy" DOUBLE PRECISION,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "metadata" JSONB DEFAULT '{}',

    CONSTRAINT "Location_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrackingData" (
    "id" SERIAL NOT NULL,
    "userId" TEXT NOT NULL,
    "androidId" TEXT,
    "sessionId" TEXT,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "battery" INTEGER,
    "accuracy" DOUBLE PRECISION,
    "speed" DOUBLE PRECISION,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TrackingData_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AttendanceSession" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "punchInTime" TIMESTAMP(3) NOT NULL,
    "punchInLocation" TEXT NOT NULL,
    "punchInBattery" INTEGER,
    "punchInAddress" TEXT,
    "punchOutTime" TIMESTAMP(3),
    "punchOutLocation" TEXT,
    "punchOutBattery" INTEGER,
    "punchOutAddress" TEXT,
    "totalDistance" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalDuration" INTEGER,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AttendanceSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Trip" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL,
    "endedAt" TIMESTAMP(3) NOT NULL,
    "startLat" DOUBLE PRECISION NOT NULL,
    "startLng" DOUBLE PRECISION NOT NULL,
    "endLat" DOUBLE PRECISION NOT NULL,
    "endLng" DOUBLE PRECISION NOT NULL,
    "distanceMeters" DOUBLE PRECISION NOT NULL,
    "summary" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Trip_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Visit" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "sessionId" TEXT,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "address" TEXT,
    "notes" TEXT,
    "visitTime" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "battery" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Visit_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Admin_email_key" ON "Admin"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_phone_key" ON "User"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "User_androidId_key" ON "User"("androidId");

-- CreateIndex
CREATE INDEX "Location_userId_timestamp_idx" ON "Location"("userId", "timestamp");

-- CreateIndex
CREATE INDEX "TrackingData_userId_timestamp_idx" ON "TrackingData"("userId", "timestamp");

-- CreateIndex
CREATE INDEX "TrackingData_androidId_idx" ON "TrackingData"("androidId");

-- CreateIndex
CREATE INDEX "TrackingData_sessionId_idx" ON "TrackingData"("sessionId");

-- CreateIndex
CREATE INDEX "AttendanceSession_userId_punchInTime_idx" ON "AttendanceSession"("userId", "punchInTime");

-- CreateIndex
CREATE INDEX "AttendanceSession_isActive_idx" ON "AttendanceSession"("isActive");

-- CreateIndex
CREATE INDEX "Visit_userId_visitTime_idx" ON "Visit"("userId", "visitTime");

-- CreateIndex
CREATE INDEX "Visit_sessionId_idx" ON "Visit"("sessionId");

-- AddForeignKey
ALTER TABLE "Location" ADD CONSTRAINT "Location_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrackingData" ADD CONSTRAINT "TrackingData_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AttendanceSession" ADD CONSTRAINT "AttendanceSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Trip" ADD CONSTRAINT "Trip_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Visit" ADD CONSTRAINT "Visit_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
