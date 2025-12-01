import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

// POST /realtime/device-register
export async function registerDevice(req, res) {
  try {
    const { userId, androidId, deviceModel } = req.body;
    
    if (!userId || !androidId) {
      return res.status(400).json({ error: "userId and androidId required" });
    }

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        androidId,
        deviceModel: deviceModel || null,
      },
    });

    res.json({
      success: true,
      message: "Device registered successfully",
      user: { id: user.id, androidId: user.androidId },
    });
  } catch (e) {
    console.error("Register device error:", e);
    res.status(500).json({ error: "Failed to register device", details: e.message });
  }
}

// POST /realtime/consent
export async function saveConsent(req, res) {
  try {
    const { userId, consented } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: "userId required" });
    }

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        trackingConsent: consented,
        consentedAt: consented ? new Date() : null,
      },
    });

    res.json({
      success: true,
      message: "Consent saved successfully",
      consented: user.trackingConsent,
    });
  } catch (e) {
    console.error("Save consent error:", e);
    res.status(500).json({ error: "Failed to save consent", details: e.message });
  }
}

// POST /realtime/track
export async function trackLocation(req, res) {
  try {
    const { userId, androidId, latitude, longitude, battery, accuracy, speed, timestamp } = req.body;
    
    if (!userId || latitude == null || longitude == null) {
      return res.status(400).json({ error: "userId, latitude, and longitude required" });
    }

    // Validate coordinates
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    
    if (isNaN(lat) || lat < -90 || lat > 90) {
      return res.status(400).json({ error: "Invalid latitude" });
    }
    
    if (isNaN(lng) || lng < -180 || lng > 180) {
      return res.status(400).json({ error: "Invalid longitude" });
    }

    // Save tracking data
    const trackingData = await prisma.trackingData.create({
      data: {
        userId,
        androidId: androidId || null,
        latitude: lat,
        longitude: lng,
        battery: battery ? parseInt(battery) : null,
        accuracy: accuracy ? parseFloat(accuracy) : null,
        speed: speed ? parseFloat(speed) : null,
        timestamp: timestamp ? new Date(timestamp) : new Date(),
      },
    });

    // Update user's last seen
    await prisma.user.update({
      where: { id: userId },
      data: { lastSeen: new Date() },
    });

    res.json({
      success: true,
      message: "Location tracked successfully",
      id: trackingData.id,
    });
  } catch (e) {
    console.error("Track location error:", e);
    res.status(500).json({ error: "Failed to track location", details: e.message });
  }
}

// GET /realtime/user/:userId/live
export async function getLiveTracking(req, res) {
  try {
    const { userId } = req.params;
    const { limit = 100 } = req.query;

    if (!userId) {
      return res.status(400).json({ error: "userId required" });
    }

    // Get user info
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        androidId: true,
        deviceModel: true,
        lastSeen: true,
        trackingConsent: true,
      },
    });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Get recent tracking data
    const trackingData = await prisma.trackingData.findMany({
      where: { userId },
      orderBy: { timestamp: "desc" },
      take: parseInt(limit),
    });

    // Calculate stats
    const now = new Date();
    const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000);
    const isOnline = user.lastSeen && user.lastSeen > fiveMinutesAgo;

    // Get today's data for distance calculation
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    
    const todayData = await prisma.trackingData.findMany({
      where: {
        userId,
        timestamp: { gte: todayStart },
      },
      orderBy: { timestamp: "asc" },
    });

    // Calculate distance
    let totalDistance = 0;
    for (let i = 1; i < todayData.length; i++) {
      const prev = todayData[i - 1];
      const curr = todayData[i];
      totalDistance += haversine(prev.latitude, prev.longitude, curr.latitude, curr.longitude);
    }

    res.json({
      success: true,
      user: {
        ...user,
        isOnline,
      },
      currentLocation: trackingData[0] || null,
      route: trackingData.map(d => ({
        lat: d.latitude,
        lng: d.longitude,
        battery: d.battery,
        timestamp: d.timestamp,
      })),
      stats: {
        totalDistance: Math.round(totalDistance),
        pointsToday: todayData.length,
        lastUpdate: user.lastSeen,
      },
    });
  } catch (e) {
    console.error("Get live tracking error:", e);
    res.status(500).json({ error: "Failed to get live tracking", details: e.message });
  }
}

// GET /realtime/user/:userId/history
export async function getTrackingHistory(req, res) {
  try {
    const { userId } = req.params;
    const { from, to, limit = 1000 } = req.query;

    if (!userId) {
      return res.status(400).json({ error: "userId required" });
    }

    const where = { userId };
    
    if (from || to) {
      where.timestamp = {};
      if (from) where.timestamp.gte = new Date(from);
      if (to) where.timestamp.lte = new Date(to);
    }

    const trackingData = await prisma.trackingData.findMany({
      where,
      orderBy: { timestamp: "asc" },
      take: parseInt(limit),
    });

    res.json({
      success: true,
      count: trackingData.length,
      data: trackingData,
    });
  } catch (e) {
    console.error("Get tracking history error:", e);
    res.status(500).json({ error: "Failed to get tracking history", details: e.message });
  }
}

// Helper: haversine distance in meters
function haversine(lat1, lon1, lat2, lon2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const R = 6371000;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
