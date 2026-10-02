# Memory Snap

**A Picture-Recall Cognitive Game for Elders with a Caregiver Content & Monitoring Portal**

*Based on the technical specification in `Memory_Snap_Implementation_Plan_NoAI.pdf`.*

---

## 🌟 Overview

Memory Snap gives elderly users a light, friendly, and empowering cognitive visual exercise:
1. **Image Reveal**: A photo is shown for a configurable viewing duration (e.g. 8–12 seconds) with a prominent circular countdown ring.
2. **Question Step**: The photo fades away and a simple question is asked with 2–4 large tap targets (e.g., *"What color was the teapot?"*, *"How many bananas were in the fruit bowl?"*).
3. **Gentle Feedback**: Immediate warm auditory chime and gentle encouraging visual feedback (*"Wonderful!"*, *"Good try!"*).
4. **Session Celebration**: Qualitative stars and confetti summary without harsh score percentages.

### 🛡️ 100% Caregiver-Authored Content (No AI)
Every photo, question, and answer choice is hand-authored by the caregiver. Caregivers can:
- Upload photos from their computer or phone (or pick from curated starter packs).
- Manage their library (Add, Edit, and Soft-Delete with one-click restore).
- Configure viewing durations, difficulty levels, round counts, and optional 4-digit PINs.
- Monitor 30-day accuracy trends, response-time changes (cognitive fatigue proxy), streak calendars, and card-level miss rates.
- Export raw CSV data or print formatted clinical summary reports for doctors or family members.

---

## 🚀 Running the Application

### 1. Requirements
- Node.js v20+ (Node v24 recommended, built-in SQLite supported)
- npm v10+

### 2. Start Backend & Frontend

In two terminal windows (or using the root scripts):

**Backend (Express + SQLite on port 5050):**
```bash
cd server
npm run dev
```

**Frontend (React + Vite + Tailwind CSS on port 5174/5175):**
```bash
cd client
npm run dev
```

Visit the app in your browser: **`http://localhost:5175`** (or the port Vite prints in your terminal).

---

## 🎮 How to Test

### Elder Mode (`/play`)
- Click **"Eleanor Vance"** or **"Arthur Vance"** on the profile select screen.
- On Eleanor's profile, click **"Start Game"**.
- Watch the countdown ring during the image reveal.
- Tap **"Read Question Aloud"** to hear the question with Web Speech text-to-speech.
- Tap an answer choice to see the gentle feedback and harmonic audio chime.
- Complete the 5 rounds to see the celebratory stars and confetti!

### Caregiver Portal (`/caregiver`)
- From the profile select screen, click **"Caregiver Portal & Content Settings"** at the bottom, or toggle the navigation in top bar.
- **Dashboard**: Review Eleanor's 30-day accuracy curve, response-time chart, streak calendar, and plain-language weekly digest note.
- **Content Library**: View all active cards. Click **"Edit"** to change choices, or **"Remove"** to send a card to the Trash tab. Switch to **"Trash"** to restore cards.
- **Add New Card**: Click **"Add New Photo Card"**, select a photo or sample template, type a question, the correct answer, and distractors, and click Save. It appears instantly in the elder's game!
- **Elder Profiles**: Adjust Eleanor or Arthur's viewing duration (seconds), round count, difficulty, or 4-digit PIN.
- **Reports**: View the formatted clinical summary report and click **"Print Report (PDF)"** or **"Export Raw CSV"**.

---

## 🏗️ Architecture & Tech Stack

- **Frontend**: React 19, TypeScript, Vite, Tailwind CSS v4, Lucide React, Canvas Confetti.
- **Backend**: Node.js, Express, `node:sqlite` (zero-dependency native SQLite), Multer for image uploads.
- **Accessibility**: WCAG AAA high-contrast typography, large touch targets (>=68px), Web Speech API for TTS read-aloud, synthesized gentle Web Audio API chimes.
