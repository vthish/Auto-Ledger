# 🚦 Auto-Ledger 📱  
### Smart Digital Driving License & Penalty Points System (Sri Lanka)

An **enterprise-level full-stack system** designed for managing digital driving licenses, traffic violations, and penalty points tracking in Sri Lanka.

This project is developed as the **Final Year HND in Software Engineering project**.

---

## ✨ Overview

Auto-Ledger is a **multi-platform ecosystem** consisting of:

- 👨‍✈️ Driver Mobile App  
- 🚓 Police Mobile App  
- 🖥️ Admin Web Portal (DMT Admin + Police Admin)  
- ⚙️ Secure Backend API  
- 🗄️ Scalable Database Infrastructure  

---

## 🏛️ System Architecture (Monorepo)

| Component | Technology |
|----------|------------|
| 📱 Mobile Frontend | Flutter & Dart (Driver App + Police App) |
| 🖥️ Web Frontend | React.js with Next.js (Admin Panels) |
| ⚙️ Backend | NestJS (TypeScript REST API) |
| 🗄️ Database | PostgreSQL (Neon / AWS RDS) |
| ⚡ Cache | Redis (Upstash) |
| 🐳 Infrastructure | Docker & Docker Compose |

---

## 📂 Repository Structure

```bash
📦 Auto-Ledger-App
 ┣ 📂 frontend_apps
 ┃ ┣ 📂 AutoLedger              # Driver Mobile App (Flutter)
 ┃ ┣ 📂 AutoLedgerPolice        # Police Mobile App (Flutter)
 ┃ ┣ 📂 DMT_Admin               # DMT Admin Web Portal (Next.js)
 ┃ ┗ 📂 Police_Admin            # Police Admin Web Portal (Next.js)
 ┣ 📂 backend
 ┃ ┗ 📂 nest-api                # NestJS Backend API
 ┗ 📜 docker-compose.yml        # Local infrastructure (DB + Redis)
