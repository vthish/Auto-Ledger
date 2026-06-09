import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Starting database seeding for Auto-Ledger...');

  const dmtPlainPassword = 'DmtAdmin@Password123!';
  const policePlainPassword = 'PoliceAdmin@Password123!';

  const saltRounds = 10;
  const hashedDmtPassword = await bcrypt.hash(dmtPlainPassword, saltRounds);
  const hashedPolicePassword = await bcrypt.hash(
    policePlainPassword,
    saltRounds,
  );

  const dmtAdmin = await prisma.dMT_Admin.create({
    data: {
      name: 'Main DMT Admin',
      password: hashedDmtPassword,
    },
  });
  console.log(
    `DMT Admin Created! -> ID: ${dmtAdmin.dmt_Admin_Id} | Password: ${dmtPlainPassword}`,
  );

  const policeAdmin = await prisma.police_Admin.create({
    data: {
      name: 'Main Police Admin',
      password: hashedPolicePassword,
    },
  });
  console.log(
    `Police Admin Created! -> ID: ${policeAdmin.police_Admin_Id} | Password: ${policePlainPassword}`,
  );

  console.log('Seeding finished successfully!');
}

main()
  .catch((e) => {
    console.error('Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
