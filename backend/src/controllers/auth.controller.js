import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
const prisma = new PrismaClient();

export async function login(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: "Email and password required" });

    const admin = await prisma.admin.findUnique({ where: { email } });
    if (!admin) return res.status(401).json({ error: "Invalid credentials" });

    const ok = await bcrypt.compare(password, admin.password);
    if (!ok) return res.status(401).json({ error: "Invalid credentials" });

    const token = jwt.sign({ id: admin.id, role: "admin", email: admin.email }, process.env.JWT_SECRET, { expiresIn: "8h" });
    res.json({ token, user: { id: admin.id, email: admin.email, name: admin.name } });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Server error" });
  }
}
