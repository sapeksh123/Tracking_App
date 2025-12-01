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

// POST /tracking/ping
export async function postPing(req, res) {
  try {
    const { userId, lat, lng, accuracy, recordedAt } = req.body;
    
    // Validation
    if (!userId || lat == null || lng == null || !recordedAt) {
      return res.status(400).json({
        error: "Missing required fields",
        required: ["userId", "lat", "lng", "recordedAt"]
      });
    }

    // Validate coordinates
    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    
    if (isNaN(latitude) || latitude < -90 || latitude > 90) {
      return res.status(400).json({ error: "Invalid latitude value" });
    }
    
    if (isNaN(longitude) || longitude < -180 || longitude > 180) {
      return res.status(400).json({ error: "Invalid longitude value" });
    }

    // Ensure user exists
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Create location record
    const loc = await prisma.location.create({
      data: {
        userId,
        latitude,
        longitude,
        accuracy: accuracy ? parseFloat(accuracy) : null,
        timestamp: new Date(recordedAt),
        metadata: {},
      },
    });

    res.json({
      success: true,
      location: loc
    });
  } catch (e) {
    console.error("Post ping error:", e);
    res.status(500).json({ error: "Failed to save location", details: e.message });
  }
}

// GET /tracking/user/:id/pings
export async function getPings(req, res) {
  try {
    const { id } = req.params;
    const { from, to, limit } = req.query;
    
    if (!id) {
      return res.status(400).json({ error: "User ID required" });
    }

    // Verify user exists
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const where = { userId: id };
    const q = {
      where,
      orderBy: { timestamp: "asc" },
      take: limit ? parseInt(limit) : 5000,
    };

    // Filtering by date
    if (from || to) {
      q.where.timestamp = {};
      if (from) q.where.timestamp.gte = new Date(from);
      if (to) q.where.timestamp.lte = new Date(to);
    }

    const rows = await prisma.location.findMany(q);

    res.json({
      success: true,
      count: rows.length,
      pings: rows
    });
  } catch (e) {
    console.error("Get pings error:", e);
    res.status(500).json({ error: "Failed to fetch pings", details: e.message });
  }
}

// GET /tracking/user/:id/route?from=&to=  -> returns GeoJSON style object
export async function getRoute(req, res) {
  try {
    const { id } = req.params;
    const { from, to } = req.query;

    if (!id) {
      return res.status(400).json({ error: "User ID required" });
    }

    // Verify user exists
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const where = { userId: id };
    if (from || to) {
      where.timestamp = {};
      if (from) where.timestamp.gte = new Date(from);
      if (to) where.timestamp.lte = new Date(to);
    }

    const rows = await prisma.location.findMany({
      where,
      orderBy: { timestamp: "asc" }
    });

    const coordinates = rows.map((r) => [
      r.longitude,
      r.latitude,
      r.timestamp.toISOString()
    ]);

    res.json({
      success: true,
      type: "Feature",
      geometry: {
        type: "LineString",
        coordinates
      },
      properties: {
        userId: id,
        count: rows.length,
        from: from || null,
        to: to || null
      }
    });
  } catch (e) {
    console.error("Get route error:", e);
    res.status(500).json({ error: "Failed to fetch route", details: e.message });
  }
}

// Simple trip segmentation: gap > 20 minutes => new trip
export async function generateTripsForUser(req, res) {
  try {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({ error: "User ID required" });
    }

    // Verify user exists
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const rows = await prisma.location.findMany({
      where: { userId: id },
      orderBy: { timestamp: "asc" }
    });

    if (!rows.length) {
      return res.json({
        success: true,
        message: "No location data available",
        trips: []
      });
    }

    const trips = [];
    let current = [rows[0]];

    for (let i = 1; i < rows.length; i++) {
      const prev = rows[i - 1];
      const curr = rows[i];
      const gapMs = curr.timestamp.getTime() - prev.timestamp.getTime();
      
      if (gapMs > 20 * 60 * 1000) {
        // finalize current trip
        if (current.length >= 2) trips.push(current);
        current = [curr];
      } else {
        current.push(curr);
      }
    }
    
    if (current.length >= 2) trips.push(current);

    // persist trips
    const created = [];
    for (const t of trips) {
      const start = t[0];
      const end = t[t.length - 1];
      let distance = 0;
      
      for (let i = 1; i < t.length; i++) {
        distance += haversine(
          t[i - 1].latitude,
          t[i - 1].longitude,
          t[i].latitude,
          t[i].longitude
        );
      }

      const trip = await prisma.trip.create({
        data: {
          userId: id,
          startedAt: start.timestamp,
          endedAt: end.timestamp,
          startLat: start.latitude,
          startLng: start.longitude,
          endLat: end.latitude,
          endLng: end.longitude,
          distanceMeters: distance,
          summary: { points: t.length },
        },
      });
      created.push(trip);
    }

    res.json({
      success: true,
      message: `Generated ${created.length} trips`,
      trips: created
    });
  } catch (e) {
    console.error("Generate trips error:", e);
    res.status(500).json({ error: "Failed to generate trips", details: e.message });
  }
}

// GET /tracking/user/:id/trips
export async function getTrips(req, res) {
  try {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({ error: "User ID required" });
    }

    // Verify user exists
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const trips = await prisma.trip.findMany({
      where: { userId: id },
      orderBy: { startedAt: "desc" }
    });

    res.json({
      success: true,
      count: trips.length,
      trips
    });
  } catch (e) {
    console.error("Get trips error:", e);
    res.status(500).json({ error: "Failed to fetch trips", details: e.message });
  }
}
