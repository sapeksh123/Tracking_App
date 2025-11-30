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
    if (!userId || lat == null || lng == null || !recordedAt) {
      return res.status(400).json({ error: "Missing fields" });
    }
    // Ensure user exists
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: "User not found" });

    const loc = await prisma.location.create({
      data: {
        userId,
        latitude: parseFloat(lat),
        longitude: parseFloat(lng),
        accuracy: accuracy ? parseFloat(accuracy) : null,
        timestamp: new Date(recordedAt),
        metadata: {},
      },
    });
    res.json(loc);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
}

// GET /tracking/user/:id/pings
export async function getPings(req, res) {
  try {
    const { id } = req.params;
    const { from, to, limit } = req.query;
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
    res.json(rows);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
}

// GET /tracking/user/:id/route?from=&to=  -> returns GeoJSON style object
export async function getRoute(req, res) {
  try {
    const { id } = req.params;
    const { from, to } = req.query;
    const where = { userId: id };
    if (from || to) {
      where.timestamp = {};
      if (from) where.timestamp.gte = new Date(from);
      if (to) where.timestamp.lte = new Date(to);
    }
    const rows = await prisma.location.findMany({ where, orderBy: { timestamp: "asc" } });
    const coordinates = rows.map((r) => [r.longitude, r.latitude, r.timestamp.toISOString()]);
    res.json({ type: "Feature", geometry: { type: "LineString", coordinates }, properties: { count: rows.length } });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
}

// Simple trip segmentation: gap > 20 minutes => new trip
export async function generateTripsForUser(req, res) {
  try {
    const { id } = req.params;
    const rows = await prisma.location.findMany({ where: { userId: id }, orderBy: { timestamp: "asc" } });
    if (!rows.length) return res.json({ trips: [] });

    const trips = [];
    let current = [rows[0]];

    for (let i = 1; i < rows.length; i++) {
      const prev = rows[i - 1];
      const curr = rows[i];
      const gapMs = curr.timestamp.getTime() - prev.timestamp.getTime();
      if (gapMs > 20 * 60 * 1000) {
        // finalize current
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
        distance += haversine(t[i - 1].latitude, t[i - 1].longitude, t[i].latitude, t[i].longitude);
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

    res.json({ trips: created });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
}

// GET /tracking/user/:id/trips
export async function getTrips(req, res) {
  try {
    const { id } = req.params;
    const trips = await prisma.trip.findMany({ where: { userId: id }, orderBy: { startedAt: "desc" } });
    res.json(trips);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
}
