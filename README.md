# Auto-Ledger-App 🚦📱

An enterprise-level Smart Digital Driving License and Penalty Points System for Sri Lanka.
Developed as the Final Year Project for HND in Software Engineering.

## 🏛 Architecture (Monorepo)

- **Frontend:** Flutter & Dart (Driver App & Police Enforcement App)
- **Backend:** Nest.js (TypeScript) API
- **Database:** PostgreSQL (Neon.tech / AWS RDS)
- **Caching & Real-time:** Redis (Upstash)
- **Infrastructure:** Docker Containerization

## 📂 Repository Structure

- `/frontend_apps/AutoLedger` - Driver Mobile Application
- `/frontend_apps/AutoLedgerPolice` - Police Enforcement Mobile Application
- `/backend/nest-api` - Main Backend API
- `docker-compose.yml` - Local database & caching infrastructure

## 🚀 Live Deployment

![Hosted on AWS](https://img.shields.io/badge/Hosted_on-AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)

* **Main API Base URL:** [http://3.109.130.13:3000](http://3.109.130.13:3000)
* **Swagger API Documentation:** [http://3.109.130.13:3000/api](http://3.109.130.13:3000/api)

*(Note: Ensure you are connecting to the correct port depending on your local or production environment.)*

## 🤝 Development Team

- Venusha Thishan
- Thiloka Indhuwari
- Maheema Vihangi
- Chamira Hashan