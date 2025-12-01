import express from "express";
import { login, userLogin } from "../controllers/auth.controller.js";
const router = express.Router();

router.post("/login", login);
router.post("/user-login", userLogin);

export default router;
