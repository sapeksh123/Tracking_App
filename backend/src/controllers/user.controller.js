import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

export async function createUser(req, res) {
  try {
    const { name, email, phone, role } = req.body;
    if (!name) return res.status(400).json({ error: "Name required" });
    // Basic email and phone validation
    if (email && !/^\S+@\S+\.\S+$/.test(email)) return res.status(400).json({ error: 'Invalid email' });
    if (phone && !/^\+?[0-9]{6,15}$/.test(phone)) return res.status(400).json({ error: 'Invalid phone number' });

    const user = await prisma.user.create({
      data: { name, email: email || null, phone: phone || null, role: role || "user" },
    });
    res.json(user);
  } catch (e) {
    console.error(e);
    // Prisma unique constraint error handling
    if (e.code === 'P2002') {
      return res.status(409).json({ error: 'Duplicate field value', fields: e.meta?.target });
    }
    res.status(500).json({ error: e.message });
  }
}

export async function listUsers(req, res) {
  try {
    const users = await prisma.user.findMany({ orderBy: { createdAt: "desc" }, take: 200 });
    res.json(users);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
}

export async function getUser(req, res) {
  try {
    const { id } = req.params;
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return res.status(404).json({ error: "User not found" });
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}

export async function updateUser(req, res) {
  try {
    const { id } = req.params;
    const { name, email, phone, role, isActive } = req.body;
    if (email && !/^\S+@\S+\.\S+$/.test(email)) return res.status(400).json({ error: 'Invalid email' });
    if (phone && !/^\+?[0-9]{6,15}$/.test(phone)) return res.status(400).json({ error: 'Invalid phone number' });
    const user = await prisma.user.update({
      where: { id },
      data: { name, email, phone, role, isActive },
    });
    res.json(user);
  } catch (e) {
    console.error(e);
    if (e.code === 'P2002') return res.status(409).json({ error: 'Duplicate field value', fields: e.meta?.target });
    res.status(500).json({ error: e.message });
  }
}

export async function deleteUser(req, res) {
  try {
    const { id } = req.params;
    await prisma.user.update({ where: { id }, data: { isActive: false } });
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
