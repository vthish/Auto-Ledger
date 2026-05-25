-- AlterEnum
ALTER TYPE "FineStatus" ADD VALUE 'RESOLVED';

-- AlterEnum
ALTER TYPE "LicenseStatus" ADD VALUE 'COURT_PENDING';

-- AlterTable
ALTER TABLE "Fine" ALTER COLUMN "dueDate" DROP NOT NULL;

-- AlterTable
ALTER TABLE "OffenseCategory" ADD COLUMN     "isCourtCase" BOOLEAN NOT NULL DEFAULT false;
