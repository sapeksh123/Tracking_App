import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

// POST /visits/mark - Mark a visit
export async function markVisit(req, res) {
  try {
    console.log("📍 Mark visit request received:", {
      body: req.body,
      headers: req.headers['content-type'],
    });

    const { userId, sessionId, latitude, longitude, address, notes, battery } = req.body;

    // Validate required fields
    if (!userId) {
      console.error("❌ Missing userId");
      return res.status(400).json({ error: "userId is required" });
    }

    if (latitude == null || latitude === undefined) {
      console.error("❌ Missing latitude");
      return res.status(400).json({ error: "latitude is required" });
    }

    if (longitude == null || longitude === undefined) {
      console.error("❌ Missing longitude");
      return res.status(400).json({ error: "longitude is required" });
    }

    // Validate coordinates
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);

    if (isNaN(lat) || lat < -90 || lat > 90) {
      console.error("❌ Invalid latitude:", latitude);
      return res.status(400).json({ error: `Invalid latitude: ${latitude}` });
    }

    if (isNaN(lng) || lng < -180 || lng > 180) {
      console.error("❌ Invalid longitude:", longitude);
      return res.status(400).json({ error: `Invalid longitude: ${longitude}` });
    }

    console.log("✓ Validation passed, creating visit...");

    // Create visit
    const visit = await prisma.visit.create({
      data: {
        userId,
        sessionId: sessionId || null,
        latitude: lat,
        longitude: lng,
        address: address || null,
        notes: notes || null,
        battery: battery ? parseInt(battery) : null,
        visitTime: new Date(),
      },
    });

    console.log("✓ Visit created successfully:", visit.id);

    res.json({
      success: true,
      message: "Visit marked successfully",
      visit,
    });
  } catch (e) {
    console.error("❌ Mark visit error:", e);
    console.error("Error details:", {
      message: e.message,
      code: e.code,
      meta: e.meta,
    });
    res.status(500).json({ 
      error: "Failed to mark visit", 
      details: e.message,
      code: e.code 
    });
  }
}

// GET /visits/user/:userId - Get user's visits
export async function getUserVisits(req, res) {
  try {
    const { userId } = req.params;
    const { sessionId, from, to, limit = 100 } = req.query;

    if (!userId) {
      return res.status(400).json({ error: "userId required" });
    }

    const where = { userId };

    if (sessionId) {
      where.sessionId = sessionId;
    }

    if (from || to) {
      where.visitTime = {};
      if (from) where.visitTime.gte = new Date(from);
      if (to) where.visitTime.lte = new Date(to);
    }

    const visits = await prisma.visit.findMany({
      where,
      orderBy: { visitTime: "desc" },
      take: parseInt(limit),
    });

    res.json({
      success: true,
      count: visits.length,
      visits,
    });
  } catch (e) {
    console.error("Get user visits error:", e);
    res.status(500).json({ error: "Failed to get visits", details: e.message });
  }
}

// GET /visits/:visitId - Get single visit
export async function getVisit(req, res) {
  try {
    const { visitId } = req.params;

    const visit = await prisma.visit.findUnique({
      where: { id: visitId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
      },
    });

    if (!visit) {
      return res.status(404).json({ error: "Visit not found" });
    }

    res.json({
      success: true,
      visit,
    });
  } catch (e) {
    console.error("Get visit error:", e);
    res.status(500).json({ error: "Failed to get visit", details: e.message });
  }
}

// PUT /visits/:visitId - Update visit
export async function updateVisit(req, res) {
  try {
    const { visitId } = req.params;
    const { address, notes } = req.body;

    const visit = await prisma.visit.update({
      where: { id: visitId },
      data: {
        ...(address !== undefined && { address }),
        ...(notes !== undefined && { notes }),
      },
    });

    res.json({
      success: true,
      message: "Visit updated successfully",
      visit,
    });
  } catch (e) {
    console.error("Update visit error:", e);
    res.status(500).json({ error: "Failed to update visit", details: e.message });
  }
}

// DELETE /visits/:visitId - Delete visit
export async function deleteVisit(req, res) {
  try {
    const { visitId } = req.params;

    await prisma.visit.delete({
      where: { id: visitId },
    });

    res.json({
      success: true,
      message: "Visit deleted successfully",
    });
  } catch (e) {
    console.error("Delete visit error:", e);
    res.status(500).json({ error: "Failed to delete visit", details: e.message });
  }
}

// GET /visits/session/:sessionId - Get visits for a session
export async function getSessionVisits(req, res) {
  try {
    const { sessionId } = req.params;

    const visits = await prisma.visit.findMany({
      where: { sessionId },
      orderBy: { visitTime: "asc" },
    });

    res.json({
      success: true,
      count: visits.length,
      visits,
    });
  } catch (e) {
    console.error("Get session visits error:", e);
    res.status(500).json({ error: "Failed to get session visits", details: e.message });
  }
}
