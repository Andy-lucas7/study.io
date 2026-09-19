<h1 align="center">
  📚 Study.io
</h1>

<p align="center">
  <b>Elevate your continuous learning experience.</b><br>
  <i>A full-stack web application to organize, track, and manage your study goals.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Stack-Full%20Stack-blueviolet.svg" alt="Full Stack" />
  <img src="https://img.shields.io/badge/Frontend-React-61DAFB.svg" alt="React" />
  <img src="https://img.shields.io/badge/Database-PostgreSQL-336791.svg" alt="PostgreSQL" />
</p>

---

## 💡 About The Project

**Study.io** is a comprehensive platform built to help students, self-taught developers, and lifelong learners organize their study routines. In a world full of scattered tutorials, disjointed notes, and endless tabs, Study.io provides a centralized hub to track your progress, store your insights, and maintain focus on your educational goals.

### ✨ Core Features

*   **Goal Tracking**: Set high-level study goals and break them down into actionable modules and tasks.
*   **Progress Dashboard**: Visual analytics to see your learning consistency, hours invested, and completion rates.
*   **Knowledge Base**: An integrated markdown editor for taking structured notes that are easily searchable and categorizable.
*   **Resource Manager**: Save and tag links to articles, videos, and documentation for later reference.
*   **Intuitive UI/UX**: A clean, distraction-free interface designed to keep you focused on what matters most—learning.

## 🛠️ Tech Stack

*   **Frontend**: React, JavaScript/TypeScript, CSS/Styled Components
*   **Backend**: Node.js / Express (or corresponding backend language)
*   **Database**: PostgreSQL
*   **Tools**: Git, Docker (optional for local DB setup)

## 🚀 Getting Started

### Prerequisites
*   Node.js (v16 or higher)
*   npm or yarn
*   PostgreSQL running locally

### Installation & Setup

1. Clone the repository
   ```sh
   git clone https://github.com/Andy-lucas7/study.io.git
   cd study.io
   ```

2. Install dependencies for the backend
   ```sh
   cd backend
   npm install
   ```

3. Configure Environment Variables
   Create a `.env` file in the root of your backend directory and add your database credentials:
   ```env
   DATABASE_URL=postgres://user:password@localhost:5432/studyio
   PORT=5000
   ```

4. Install dependencies for the frontend
   ```sh
   cd ../frontend
   npm install
   ```

5. Run the application
   You can run the frontend and backend concurrently:
   ```sh
   npm run dev
   ```

## 🧠 What I Learned

Building Study.io was an excellent exercise in full-stack engineering. It challenged me to design a normalized relational database schema, build a robust API, and consume it through a dynamic React frontend with complex state management. Connecting the dots between database performance, backend logic, and user interface responsiveness was the core focus of this project.

---
<p align="center">Made with ❤️ by Lucas Andrey</p>
