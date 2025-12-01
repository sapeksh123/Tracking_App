import express from "express";
import {
  punchIn,
  punchOut,
  getCurrentSession,
  getAttendanceHistory,
  getSessionRoute,
} from "../controllers/attendance.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";

const router = express.Router();

// User endpoints
router.post("/punch-in", requireAuth, punchIn);
router.post("/punch-out", requireAuth, punchOut);
router.get("/user/:userId/current", requireAuth, getCurrentSession);
router.get("/user/:userId/history", requireAuth, getAttendanceHistory);
router.get("/user/:userId/session/:sessionId/route", requireAuth, getSessionRoute);

export default router;
