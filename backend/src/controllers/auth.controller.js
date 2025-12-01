import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
const prisma = new PrismaClient();

export async function login(req, res) {
  try {
    const { email, password } = req.body;
    
    // Validation
    if (!email || !password) {
      return res.status(400).json({ error: "Email and password required" });
    }

    // Find admin
    const admin = await prisma.admin.findUnique({ where: { email } });
    if (!admin) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // Verify password
    const ok = await bcrypt.compare(password, admin.password);
    if (!ok) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // Check JWT_SECRET exists
    if (!process.env.JWT_SECRET) {
      console.error("JWT_SECRET not configured");
      return res.status(500).json({ error: "Server configuration error" });
    }

    // Generate token
    const token = jwt.sign(
      { id: admin.id, role: "admin", email: admin.email },
      process.env.JWT_SECRET,
      { expiresIn: "8h" }
    );

    // Success response
    res.json({
      success: true,
      token,
      user: {
        id: admin.id,
        email: admin.email,
        name: admin.name,
        role: "admin"
      }
    });
  } catch (e) {
    console.error("Login error:", e);
    res.status(500).json({ error: "Server error", details: e.message });
  }
}

export async function userLogin(req, res) {
  try {
    const { phone, password } = req.body;
    
    // Validation
    if (!phone || !password) {
      return res.status(400).json({ error: "Phone and password required" });
    }

    // Clean phone number
    const cleanPhone = phone.trim().replace(/[^0-9]/g, '');

    // Find user by phone
    const user = await prisma.user.findUnique({ 
      where: { phone: cleanPhone } 
    });
    
    if (!user) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({ error: "User account is deactivated" });
    }

    // Verify password
    const ok = await bcrypt.compare(password, user.password);
    if (!ok) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // Check JWT_SECRET exists
    if (!process.env.JWT_SECRET) {
      console.error("JWT_SECRET not configured");
      return res.status(500).json({ error: "Server configuration error" });
    }

    // Generate token
    const token = jwt.sign(
      { id: user.id, role: user.role, phone: user.phone },
      process.env.JWT_SECRET,
      { expiresIn: "30d" }
    );

    // Success response (don't send password)
    const { password: _, ...userWithoutPassword } = user;
    
    res.json({
      success: true,
      token,
      user: userWithoutPassword
    });
  } catch (e) {
    console.error("User login error:", e);
    res.status(500).json({ error: "Server error", details: e.message });
  }
}
