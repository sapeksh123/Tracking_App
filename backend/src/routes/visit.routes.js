import express from "express";
import {
  markVisit,
  getUserVisits,
  getVisit,
  updateVisit,
  deleteVisit,
  getSessionVisits,
} from "../controllers/visit.controller.js";

const router = express.Router();

// Mark a visit
router.post("/mark", markVisit);

// Get user's visits
router.get("/user/:userId", getUserVisits);

// Get single visit
router.get("/:visitId", getVisit);

// Update visit
router.put("/:visitId", updateVisit);

// Delete visit
router.delete("/:visitId", deleteVisit);

// Get visits for a session
router.get("/session/:sessionId", getSessionVisits);

export default router;
