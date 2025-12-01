import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

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

// POST /attendance/punch-in
export async function punchIn(req, res) {
  try {
    const { userId, latitude, longitude, battery, address } = req.body;
    
    if (!userId || latitude == null || longitude == null) {
      return res.status(400).json({ error: "userId, latitude, and longitude required" });
    }

    // Check if user already punched in
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    if (user.isPunchedIn) {
      return res.status(400).json({ error: "Already punched in. Please punch out first." });
    }

    // Create attendance session
    const session = await prisma.attendanceSession.create({
      data: {
        userId,
        punchInTime: new Date(),
        punchInLocation: `${latitude},${longitude}`,
        punchInBattery: battery || null,
        punchInAddress: address || null,
        isActive: true,
      },
    });

    // Update user status
    await prisma.user.update({
      where: { id: userId },
      data: {
        isPunchedIn: true,
        currentSession: session.id,
        lastSeen: new Date(),
      },
    });

    res.json({
      success: true,
      message: "Punched in successfully",
      session: {
        id: session.id,
        punchInTime: session.punchInTime,
        punchInLocation: session.punchInLocation,
      },
    });
  } catch (e) {
    console.error("Punch in error:", e);
    res.status(500).json({ error: "Failed to punch in", details: e.message });
  }
}

// POST /attendance/punch-out
export async function punchOut(req, res) {
  try {
    const { userId, latitude, longitude, battery, address } = req.body;
    
    if (!userId || latitude == null || longitude == null) {
      return res.status(400).json({ error: "userId, latitude, and longitude required" });
    }

    // Get user and current session
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    if (!user.isPunchedIn || !user.currentSession) {
      return res.status(400).json({ error: "Not punched in" });
    }

    // Get session
    const session = await prisma.attendanceSession.findUnique({
      where: { id: user.currentSession },
    });

    if (!session) {
      return res.status(404).json({ error: "Session not found" });
    }

    // Calculate total distance from tracking data
    const trackingData = await prisma.trackingData.findMany({
      where: { sessionId: session.id },
      orderBy: { timestamp: "asc" },
    });

    let totalDistance = 0;
    for (let i = 1; i < trackingData.length; i++) {
      const prev = trackingData[i - 1];
      const curr = trackingData[i];
      totalDistance += haversine(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude
      );
    }

    // Calculate duration in minutes
    const punchOutTime = new Date();
    const duration = Math.floor(
      (punchOutTime.getTime() - session.punchInTime.getTime()) / (1000 * 60)
    );

    // Update session
    const updatedSession = await prisma.attendanceSession.update({
      where: { id: session.id },
      data: {
        punchOutTime,
        punchOutLocation: `${latitude},${longitude}`,
        punchOutBattery: battery || null,
        punchOutAddress: address || null,
        totalDistance: Math.round(totalDistance),
        totalDuration: duration,
        isActive: false,
      },
    });

    // Update user status
    await prisma.user.update({
      where: { id: userId },
      data: {
        isPunchedIn: false,
        currentSession: null,
        lastSeen: new Date(),
      },
    });

    res.json({
      success: true,
      message: "Punched out successfully",
      session: {
        id: updatedSession.id,
        punchInTime: updatedSession.punchInTime,
        punchOutTime: updatedSession.punchOutTime,
        totalDistance: updatedSession.totalDistance,
        totalDuration: updatedSession.totalDuration,
      },
    });
  } catch (e) {
    console.error("Punch out error:", e);
    res.status(500).json({ error: "Failed to punch out", details: e.message });
  }
}

// GET /attendance/user/:userId/current
export async function getCurrentSession(req, res) {
  try {
    const { userId } = req.params;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        isPunchedIn: true,
        currentSession: true,
      },
    });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    if (!user.isPunchedIn || !user.currentSession) {
      return res.json({
        success: true,
        isPunchedIn: false,
        session: null,
      });
    }

    const session = await prisma.attendanceSession.findUnique({
      where: { id: user.currentSession },
    });

    // Get tracking data for this session
    const trackingData = await prisma.trackingData.findMany({
      where: { sessionId: session.id },
      orderBy: { timestamp: "desc" },
      take: 100,
    });

    // Calculate current distance
    let totalDistance = 0;
    for (let i = 1; i < trackingData.length; i++) {
      const prev = trackingData[i - 1];
      const curr = trackingData[i];
      totalDistance += haversine(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude
      );
    }

    // Calculate current duration
    const duration = Math.floor(
      (new Date().getTime() - session.punchInTime.getTime()) / (1000 * 60)
    );

    res.json({
      success: true,
      isPunchedIn: true,
      session: {
        ...session,
        currentDistance: Math.round(totalDistance),
        currentDuration: duration,
        trackingPoints: trackingData.length,
      },
    });
  } catch (e) {
    console.error("Get current session error:", e);
    res.status(500).json({ error: "Failed to get session", details: e.message });
  }
}

// GET /attendance/user/:userId/history
export async function getAttendanceHistory(req, res) {
  try {
    const { userId } = req.params;
    const { from, to, limit = 30 } = req.query;

    const where = { userId };
    
    if (from || to) {
      where.punchInTime = {};
      if (from) where.punchInTime.gte = new Date(from);
      if (to) where.punchInTime.lte = new Date(to);
    }

    const sessions = await prisma.attendanceSession.findMany({
      where,
      orderBy: { punchInTime: "desc" },
      take: parseInt(limit),
    });

    // Enhance active sessions with current data
    const enhancedSessions = await Promise.all(
      sessions.map(async (session) => {
        if (!session.isActive) {
          return session;
        }

        // Get tracking data for active session
        const trackingData = await prisma.trackingData.findMany({
          where: { sessionId: session.id },
          orderBy: { timestamp: "asc" },
        });

        // Calculate current distance
        let totalDistance = 0;
        for (let i = 1; i < trackingData.length; i++) {
          const prev = trackingData[i - 1];
          const curr = trackingData[i];
          totalDistance += haversine(
            prev.latitude,
            prev.longitude,
            curr.latitude,
            curr.longitude
          );
        }

        // Calculate current duration
        const duration = Math.floor(
          (new Date().getTime() - session.punchInTime.getTime()) / (1000 * 60)
        );

        // Get latest tracking point for current battery
        const latestTracking = trackingData[0]; // Already ordered desc in query above
        
        // Get visit count
        const visitCount = await prisma.visit.count({
          where: { sessionId: session.id },
        });

        return {
          ...session,
          currentDistance: Math.round(totalDistance),
          currentDuration: duration,
          trackingPoints: trackingData.length,
          currentBattery: latestTracking?.battery || session.punchInBattery,
          visitCount,
        };
      })
    );

    res.json({
      success: true,
      count: enhancedSessions.length,
      sessions: enhancedSessions,
    });
  } catch (e) {
    console.error("Get attendance history error:", e);
    res.status(500).json({ error: "Failed to get history", details: e.message });
  }
}

// GET /attendance/user/:userId/session/:sessionId/route
export async function getSessionRoute(req, res) {
  try {
    const { userId, sessionId } = req.params;

    const session = await prisma.attendanceSession.findFirst({
      where: {
        id: sessionId,
        userId,
      },
    });

    if (!session) {
      return res.status(404).json({ error: "Session not found" });
    }

    const trackingData = await prisma.trackingData.findMany({
      where: { sessionId },
      orderBy: { timestamp: "asc" },
    });

    // Calculate current duration if session is active
    let currentDuration = session.totalDuration;
    if (session.isActive) {
      currentDuration = Math.floor(
        (new Date().getTime() - session.punchInTime.getTime()) / (1000 * 60)
      );
    }

    // Calculate current distance from tracking data
    let totalDistance = 0;
    for (let i = 1; i < trackingData.length; i++) {
      const prev = trackingData[i - 1];
      const curr = trackingData[i];
      totalDistance += haversine(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude
      );
    }
    const currentDistance = session.isActive ? Math.round(totalDistance) : session.totalDistance;

    // Get visit count
    const visitCount = await prisma.visit.count({
      where: { sessionId },
    });

    // Get latest tracking point for current battery
    const latestTracking = trackingData[trackingData.length - 1];

    // Convert to GeoJSON format
    const coordinates = trackingData.map((d) => [
      d.longitude,
      d.latitude,
      d.timestamp.toISOString(),
      d.battery || 0,
    ]);

    res.json({
      success: true,
      session: {
        ...session,
        currentDuration,
        currentDistance,
        trackingPoints: trackingData.length,
        visitCount,
        currentBattery: session.isActive ? (latestTracking?.battery || session.punchInBattery) : session.punchOutBattery,
      },
      route: {
        type: "Feature",
        geometry: {
          type: "LineString",
          coordinates,
        },
        properties: {
          sessionId,
          userId,
          pointCount: trackingData.length,
          distance: currentDistance,
          duration: currentDuration,
        },
      },
    });
  } catch (e) {
    console.error("Get session route error:", e);
    res.status(500).json({ error: "Failed to get route", details: e.message });
  }
}
