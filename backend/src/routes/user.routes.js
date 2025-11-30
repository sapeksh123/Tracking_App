import express from "express";
import {
  createUser,
  listUsers,
  getUser,
  updateUser,
  deleteUser,
} from "../controllers/user.controller.js";
import { requireAdmin } from "../middlewares/auth.middleware.js";

const router = express.Router();

router.use(requireAdmin); 

router.post("/", createUser);
router.get("/", listUsers);
router.get("/:id", getUser);
router.put("/:id", updateUser);
router.delete("/:id", deleteUser);

export default router;
