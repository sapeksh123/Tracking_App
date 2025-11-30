import express from "express";
import cors from "cors";
import authRoutes from "./routes/auth.routes.js";
import userRoutes from "./routes/user.routes.js";
import trackingRoutes from "./routes/tracking.routes.js";

const app = express();
app.use(cors());
app.use(express.json());

app.use("/auth", authRoutes);
app.use("/users", userRoutes);
app.use("/tracking", trackingRoutes);

app.get("/", (req, res) => res.json({ ok: true, message: "Tracking backend Running Successfully !!" }));

export default app;
