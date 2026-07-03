# SudanFree — Standardized Product Requirements Document (PRD)

## 1. Product Overview

**Product Name:** SudanFree  
**Type:** Mobile Application (Flutter) + Web Admin Panel  
**Version:** 2.0.0+4  
**Platforms:** Android, iOS, Web  
**Primary Language:** Arabic (RTL), English (secondary)  
**Description:** A freelance marketplace and social platform for Sudan that connects freelancers with clients, featuring social networking, real-time chat, interactive map, community squads, shops, job marketplace, and safety alerts.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter / Dart (SDK >=3.6.0) |
| State Management | Provider |
| Backend | Firebase (Auth, Firestore, Storage, Functions, FCM, Analytics, Crashlytics, Performance) |
| Database | Cloud Firestore (NoSQL) |
| Media CDN | Cloudinary |
| Push Notifications | Firebase FCM + OneSignal |
| SMS/Communication | Twilio |
| Map | flutter_map + latlong2 + flutter_map_marker_cluster |
| Local Cache | Hive + SharedPreferences |
| Auth Providers | Email/Password, Google, Facebook |

---

## 3. Core Features

### F-001: Authentication & User Management
- Email/Password sign-up and login
- Google OAuth sign-in
- Facebook OAuth sign-in
- Phone OTP verification (Twilio)
- Identity/KYC verification requests
- Multi-step onboarding flow
- Profile setup (name, photo, bio, skills, location, account type)
- Account types: Freelancer, Client, Shop Owner

### F-002: Social Feed
- Create posts (text, images, videos, audio, files)
- Like, comment, reply on posts
- Stories (ephemeral 24h content)
- Share posts externally
- Mentions (@user)
- Link previews
- Trending and algorithmic feed ranking

### F-003: Freelance Marketplace (Jobs)
- Post job listings (title, description, budget, category, location, deadline)
- Browse and filter jobs
- Submit proposals with cover letter, budget, timeline
- Review, accept or reject proposals
- Offer management and acceptance flow
- Job completion and review submission
- Payment tracking

### F-004: Freelancer Discovery
- Browse freelancer profiles
- Filter by skill, location, rating
- View portfolio, reviews, endorsements
- Rank/badge system based on activity
- Contact via chat or request

### F-005: Real-Time Chat
- One-on-one messaging
- Message types: text, image, audio, file
- Message reactions and reply threading
- Online/offline presence indicators
- Contact log tracking

### F-006: Interactive Map
- Flutter Map with OSM tiles
- Marker clustering for nearby items
- Location-based freelancer/shop discovery
- Geolocation and geocoding
- Region auto-detection (Sudan states/cities)

### F-007: Squads (Communities)
- Create public or private squads
- Post and discuss within squads
- Member management (join, leave, remove)
- Squad-specific feed

### F-008: Shops
- Create and manage shop profiles
- List products/services with images and prices
- Shop discovery and browsing
- Contact shop owner via chat

### F-009: Smart Search
- Global search across users, jobs, posts, shops, squads
- Full-text and keyword search
- Filters by category, location, rating
- Search history and suggestions

### F-010: Notifications
- Firebase FCM push notifications
- OneSignal push notifications (alternative)
- In-app notification center
- Local notifications
- Notification categories: job, chat, social, system

### F-011: Safety Alerts
- Emergency/safety alert broadcasting
- Safety guidelines display
- Content reporting system (users, posts, jobs)

### F-012: Settings & Personalization
- Dark/light theme toggle
- Language switching (Arabic ↔ English)
- Lite mode (reduced data usage)
- Privacy settings
- Account management (edit profile, delete account)
- App update checker

### F-013: Admin Panel
- Flutter Web admin dashboard
- User management
- Content moderation
- Analytics overview
- Verification request review

---

## 4. Data Collections (Firestore)

| Collection | Description |
|---|---|
| `users` | User profiles, settings, verification status |
| `jobs` | Job listings with requirements and status |
| `proposals` | Freelancer job applications |
| `posts` | Social feed posts with media |
| `comments` | Post comments and replies |
| `stories` | Ephemeral 24h stories |
| `messages` / `chats` | Real-time chat messages |
| `notifications` | User notification history |
| `squads` | Community group data |
| `shops` | Shop profiles and products |
| `ads` | Promotional advertisements |
| `reviews` | User ratings and reviews |
| `endorsements` | Peer endorsements |
| `payments` | Payment transaction records |
| `requests` | Service/job requests |
| `reports` | Abuse/content reports |

---

## 5. User Flows

### 5.1 Registration & Onboarding
1. App opens → Splash screen
2. Onboarding slides (if first time)
3. Sign up (Google / Facebook / Email)
4. Phone OTP verification (optional)
5. Profile setup (name, type, location, skills)
6. Home screen

### 5.2 Job Posting & Proposal Flow
1. Client posts job → fills title, budget, category
2. Job appears in browse list
3. Freelancers submit proposals
4. Client reviews proposals → accepts one
5. Work done → client marks complete → leaves review

### 5.3 Social Post Flow
1. User creates post with optional media
2. Post appears in followers' feed
3. Users react / comment / share
4. Author receives push notification

### 5.4 Chat Flow
1. User views profile or job
2. Taps "Send Message" button
3. Chat screen opens (real-time Firestore listener)
4. Messages exchanged with media support

### 5.5 Map Discovery Flow
1. User opens Map tab
2. Map loads with clustered markers (freelancers/shops)
3. User taps marker → sees profile card
4. User can contact or view full profile

---

## 6. Non-Functional Requirements

| Requirement | Target |
|---|---|
| Performance | Cold start < 3s, smooth 60fps UI |
| Offline Support | Firestore offline persistence + Hive cache |
| Security | Firestore security rules, Firebase Auth token validation |
| Scalability | Cloud Functions for heavy operations |
| Localization | Arabic (RTL primary), English |
| Accessibility | Material Design guidelines, adequate touch targets |
| Crash Reporting | Firebase Crashlytics |
| Analytics | Firebase Analytics + custom events |

---

## 7. Cloud Functions

| Function Module | Responsibility |
|---|---|
| `notifications.js` | Send push notifications via FCM for social events |
| `users.js` | User management, role assignment, cleanup |
| `jobs.js` | Job operations, expiry, matching |
| `ads.js` | Advertisement management and delivery |
| `media.js` | Media processing and validation |
| `utils.js` | Shared helper functions |
