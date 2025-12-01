import express from "express";
import {
  registerDevice,
  saveConsent,
  trackLocation,
  getLiveTracking,
  getTrackingHistory,
} from "../controllers/realtime.controller.js";
import { requireAuth, requireAdmin } from "../middlewares/auth.middleware.js";

const router = express.Router();

// User endpoints (require authentication)
router.post("/device-register", requireAuth, registerDevice);
router.post("/consent", requireAuth, saveConsent);
router.post("/track", requireAuth, trackLocation);

// Admin endpoints
router.get("/user/:userId/live", requireAdmin, getLiveTracking);
router.get("/user/:userId/history", requireAdmin, getTrackingHistory);

export default router;
