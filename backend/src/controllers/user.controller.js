import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

export async function createUser(req, res) {
  try {
    const { name, email, phone, role } = req.body;
    
    // Validation
    if (!name || name.trim().length === 0) {
      return res.status(400).json({ error: "Name required" });
    }
    
    // Email validation
    if (email && !/^\S+@\S+\.\S+$/.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    
    // Phone validation
    if (phone && !/^\+?[0-9]{6,15}$/.test(phone)) {
      return res.status(400).json({ error: 'Invalid phone number format' });
    }

    // Create user
    const user = await prisma.user.create({
      data: {
        name: name.trim(),
        email: email?.trim() || null,
        phone: phone?.trim() || null,
        role: role || "user"
      },
    });

    // Success response
    res.json({
      success: true,
      user
    });
  } catch (e) {
    console.error("Create user error:", e);
    
    // Prisma unique constraint error
    if (e.code === 'P2002') {
      return res.status(409).json({
        error: 'User with this email or phone already exists',
        fields: e.meta?.target
      });
    }
    
    res.status(500).json({ error: "Failed to create user", details: e.message });
  }
}

export async function listUsers(req, res) {
  try {
    const users = await prisma.user.findMany({
      where: { isActive: true },
      orderBy: { createdAt: "desc" },
      take: 200
    });
    
    res.json({
      success: true,
      count: users.length,
      users
    });
  } catch (e) {
    console.error("List users error:", e);
    res.status(500).json({ error: "Failed to fetch users", details: e.message });
  }
}

export async function getUser(req, res) {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: "User ID required" });
    }
    
    const user = await prisma.user.findUnique({ where: { id } });
    
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }
    
    res.json({
      success: true,
      user
    });
  } catch (e) {
    console.error("Get user error:", e);
    res.status(500).json({ error: "Failed to fetch user", details: e.message });
  }
}

export async function updateUser(req, res) {
  try {
    const { id } = req.params;
    const { name, email, phone, role, isActive } = req.body;
    
    if (!id) {
      return res.status(400).json({ error: "User ID required" });
    }
    
    // Validation
    if (email && !/^\S+@\S+\.\S+$/.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    
    if (phone && !/^\+?[0-9]{6,15}$/.test(phone)) {
      return res.status(400).json({ error: 'Invalid phone number format' });
    }

    // Build update data object
    const updateData = {};
    if (name !== undefined) updateData.name = name.trim();
    if (email !== undefined) updateData.email = email?.trim() || null;
    if (phone !== undefined) updateData.phone = phone?.trim() || null;
    if (role !== undefined) updateData.role = role;
    if (isActive !== undefined) updateData.isActive = isActive;

    const user = await prisma.user.update({
      where: { id },
      data: updateData,
    });
    
    res.json({
      success: true,
      user
    });
  } catch (e) {
    console.error("Update user error:", e);
    
    if (e.code === 'P2002') {
      return res.status(409).json({
        error: 'Email or phone already in use',
        fields: e.meta?.target
      });
    }
    
    if (e.code === 'P2025') {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.status(500).json({ error: "Failed to update user", details: e.message });
  }
}

export async function deleteUser(req, res) {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({ error: "User ID required" });
    }
    
    // Soft delete by setting isActive to false
    await prisma.user.update({
      where: { id },
      data: { isActive: false }
    });
    
    res.json({
      success: true,
      message: "User deactivated successfully"
    });
  } catch (e) {
    console.error("Delete user error:", e);
    
    if (e.code === 'P2025') {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.status(500).json({ error: "Failed to delete user", details: e.message });
  }
}
