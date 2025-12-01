import express from "express";
import cors from "cors";
import authRoutes from "./routes/auth.routes.js";
import userRoutes from "./routes/user.routes.js";
import trackingRoutes from "./routes/tracking.routes.js";
import realtimeRoutes from "./routes/realtime.routes.js";
import attendanceRoutes from "./routes/attendance.routes.js";
import visitRoutes from "./routes/visit.routes.js";

const app = express();
app.use(cors());
app.use(express.json());

app.use("/auth", authRoutes);
app.use("/users", userRoutes);
app.use("/tracking", trackingRoutes);
app.use("/realtime", realtimeRoutes);
app.use("/attendance", attendanceRoutes);
app.use("/visits", visitRoutes);

app.get("/", (req, res) => res.json({ ok: true, message: "Tracking backend Running Successfully !!" }));

export default app;
