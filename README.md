# FIXOPS: Facility Issue Reporting & Maintenance System
**System Administration (BSIT 4B) Project**

* **Course:** System Administration (BSIT 4B)
* **Team Members:**
  * Joyce Bernadeth S. Ambuyo
  * John Laurence A. Lagapa
  * Sunday Le'Chaim L. Nadonga
  * Jay Ynewson Suarilla

---

## 🌟 Overview

**FIXOPS** is a centralized IT support and technology issue reporting platform bridging practical software engineering with real-world system administration. It replaces informal, scattered reporting channels (verbal talks, lost group chats, paper forms) with a structured digital intake workflow, real-time ticket triage, photo evidence tracking, and an immutable activity audit trail.

---

## 🏗️ Architecture & Technology Stack

* **Backend Service (Python & FastAPI):**
  * High-performance asynchronous REST API.
  * **Role-Based Access Control (RBAC):** Tiered roles (`USER`, `TECHNICIAN`, `ADMIN`) protected with JWT Bearer tokens and BCrypt salted password hashing.
  * **Local Server & Network Hosting:** Binds to `0.0.0.0:8000` to allow access across the organizational Local Area Network (LAN) for physical mobile devices and web browsers.
  * **Media Storage Management:** Safe server-side handling and static hosting of photo evidence under `/uploads/tickets/`.
  * **Activity Audit Trail:** Real-time logging of user logins, role changes, and ticket status updates with IP address and timestamp recording.
  * **Database Layer:** SQLite (local zero-configuration) with SQLAlchemy ORM, easily switchable to PostgreSQL or MySQL.
  * **Interactive API Documentation:** Auto-generated Swagger UI at `http://127.0.0.1:8000/api/v1/docs`.

* **Frontend Clients:**
  * **React Operations Portal:** Role-separated web app. **Technicians** see their assigned workload, claim support tickets, and update status and resolution notes. **Administrators** get system-wide analytics, user/RBAC controls, activity audit, and FastAPI service logs.
  * **Flutter Cross-Platform User App:** Android, iOS, and web app for end users to report technology issues with photo evidence, prioritize tickets, track progress, and receive in-app notifications.
  * **Automated In-App Notifications:** Persisted alerts are created for ticket submissions, assignments, updates, and resolutions. End users, technicians, and administrators can review and mark their own alerts as read.

---

## 🚀 Quick Start Guide

### Prerequisites
* Python 3.10+
* Flutter SDK (3.24+)
* Node.js 20+ and npm
* Google Chrome (or another modern browser) and/or Android device / emulator

### Step 1: Start Backend Server
Double-click `run_backend.bat` or run:
```powershell
cd backend
.\venv\Scripts\activate
$env:PYTHONPATH=".."
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```
The backend API is now running at:
* Swagger API Docs: `http://127.0.0.1:8000/api/v1/docs`
* Health Check: `http://127.0.0.1:8000/api/health`

### Step 2: Seed Database (Included in setup)
To re-seed sample users, tickets, and audit logs at any time:
```powershell
$env:PYTHONPATH="."
.\backend\venv\Scripts\python.exe backend\seed.py
```

### Step 3: Run the React Admin / Technician Portal
Double-click `run_admin_web.bat` or run:
```powershell
cd frontend\admin-web
npm install
npm run dev
```
Open the address printed by Vite (by default `http://localhost:5173`). The portal connects to `http://127.0.0.1:8000/api/v1`; set `VITE_API_URL` before starting Vite to use a different API URL.

### Step 4: Run the Flutter User App (Web or Mobile)
For web, double-click `frontend\run_web.bat` or run:
```powershell
cd frontend
flutter run -d chrome
```

For Android, ensure an emulator is running or a device is connected via USB:
```powershell
cd frontend
flutter run -d android
```
For iOS, open the Flutter project in Xcode and run its iOS target.

---

## 🔑 Default Demo Accounts

The database comes pre-seeded with simple demo accounts for testing and defense presentations:

| Role | Username / Email | Password | Permissions & Views |
| :--- | :--- | :--- | :--- |
| **System Administrator** | `admin` *(or `admin@fixops.local`)* | `admin` | React Portal: system analytics, support tickets, user/RBAC controls, audit trail, FastAPI service logs, notifications |
| **IT Support Technician** | `tech` *(or `tech@fixops.local`)* | `tech` | React Portal: own workload, claim unassigned tickets, update assigned ticket status and resolution notes, notifications |
| **Student / Staff (End-User)** | `user` *(or `user@fixops.local`)* | `user` | Flutter app: report prioritized tickets, attach photo evidence, track progress, receive ticket notifications |

*(The React portal has quick-login chips for the admin and technician demos; the Flutter user app has a separate user demo chip.)*

---

## 📁 Repository Directory Structure

```text
fixops/
├── backend/                  # FastAPI Application
│   ├── app/
│   │   ├── api/              # REST Endpoints (auth, tickets, users, audit_logs, stats)
│   │   ├── core/             # Security (JWT, bcrypt), config & paths
│   │   ├── db/               # SQLAlchemy engine & session setup
│   │   ├── models/           # DB Models (User, Ticket, Attachment, AuditLog)
│   │   └── schemas/          # Pydantic Request & Response DTOs
│   ├── logs/                 # System and audit log files
│   ├── uploads/              # Local server photo evidence repository
│   ├── main.py               # FastAPI application entry point
│   ├── requirements.txt      # Python dependencies
│   └── seed.py               # Database seeder script
│
├── frontend/
│   ├── admin-web/            # React + TypeScript admin/technician web portal
│   └── lib/                  # Flutter cross-platform end-user app
│
├── run_backend.bat           # One-click Windows backend launcher
├── run_admin_web.bat         # One-click Windows React portal launcher
└── README.md                 # System documentation
```
