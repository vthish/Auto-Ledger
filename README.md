🚦 Auto-Ledger 📱

An enterprise-level Smart Digital Driving License and Penalty Points System for Sri Lanka.

Developed as the Final Year Project for HND in Software Engineering.

🏛 Architecture (Monorepo)

Component

Technology Stack

📱 Frontend

Flutter & Dart (Driver App & Police Enforcement App)

⚙️ Backend

Nest.js (TypeScript) API

🗄️ Database

PostgreSQL (Neon.tech / AWS RDS)

⚡ Caching

Redis (Upstash)

🐳 Infrastructure

Docker Containerization

📂 Repository Structure

📦 Auto-Ledger-App
 ┣ 📂 frontend_apps
 ┃ ┣ 📂 AutoLedger         # Driver Mobile Application
 ┃ ┗ 📂 AutoLedgerPolice   # Police Enforcement Mobile Application
 ┣ 📂 backend
 ┃ ┗ 📂 nest-api           # Main Backend API
 ┗ 📜 docker-compose.yml   # Local database & caching infrastructure


🚀 Live Deployment

🌍 Main API Base URL: http://47.129.144.60:3000

📖 Swagger API Docs: http://47.129.144.60:3000/api-doc

Note: Ensure you are connecting to the correct port depending on your local or production environment.

🤝 Development Team

👨‍💻 Venusha Thishan

👩‍💻 Thiloka Indhuwari

👩‍💻 Maheema Vihangi

👨‍💻 Chamira Hashan
