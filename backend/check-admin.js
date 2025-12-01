import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
import dotenv from "dotenv";

dotenv.config();

const prisma = new PrismaClient();

async function checkAdmin() {
  try {
    const admins = await prisma.admin.findMany();
    console.log('\n=== All Admins in Database ===');
    console.log(JSON.stringify(admins, null, 2));
    
    if (admins.length === 0) {
      console.log('\n⚠ No admins found in database!');
      return;
    }
    
    // Test password for each admin
    for (const admin of admins) {
      console.log(`\n--- Testing admin: ${admin.email} ---`);
      const testPassword = 'admin';
      const isValid = await bcrypt.compare(testPassword, admin.password);
      console.log(`Password "admin" is ${isValid ? '✓ VALID' : '✗ INVALID'}`);
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkAdmin();
