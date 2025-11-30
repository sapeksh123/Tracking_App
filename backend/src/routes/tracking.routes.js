import express from "express";
import {
  postPing,
  getPings,
  getRoute,
  generateTripsForUser,
  getTrips,
} from "../controllers/tracking.controller.js";
import { requireAdmin } from "../middlewares/auth.middleware.js";

const router = express.Router();

// We allow posting pings without auth for quick mobile integration (common in MVP)
// In production, requireAuth + token per user should be used.
router.post("/ping", postPing);

// read pings (admin only)
router.get("/user/:id/pings", requireAdmin, getPings);
router.get("/user/:id/route", requireAdmin, getRoute);
router.post("/user/:id/generate-trips", requireAdmin, generateTripsForUser);
router.get("/user/:id/trips", requireAdmin, getTrips);

export default router;
