# Workforce Platform - Mobile App Development Tasks

> Generated from `Reqirements.txt` analysis on May 1, 2026.

## Overview
Sri Lanka's informal workers platform with multi-language support (Sinhala, Tamil, English), offline-first architecture, user authentication, job posting/applying, and community messaging.

---

## Phase 1: Core Authentication & Setup

### 1.1 Home Screen UI
- [ ] Add language switch button (top-right iconic button)
- [ ] Add welcome message in selected language
- [ ] Add hero image/app logo
- [ ] Add Register button → navigate to register screen
- [ ] Add Login button → navigate to login screen
- [ ] Test on web and Android devices

### 1.2 Login Screen
- [ ] Build login UI (image, NIC field, PIN field, login button)
- [ ] Add link to register screen
- [ ] Implement NIC + PIN validation
- [ ] Mock login API call (console log for now)
- [ ] Navigate to Dashboard on successful login
- [ ] Persist session locally (Hive)
- [ ] Test on web and Android devices

### 1.3 User Identification & Session
- [ ] Set up Hive for local data persistence
- [ ] Store user NIC uniquely (primary identifier)
- [ ] Implement session management (login/logout/auto-login)
- [ ] Create user model (NIC, first name, last name, phone, PIN, etc.)
- [ ] Add logout functionality

---

## Phase 2: Registration Flow

### 2.1 Registration Screen 1: Basic Information
- [ ] Build multi-step form UI
- [ ] First name input field
- [ ] Last name input field
- [ ] NIC input field (validate uniqueness locally)
- [ ] Phone number input field
- [ ] PIN input field (6+ digits)
- [ ] Add link to login screen
- [ ] Store Step 1 data locally (temporary state)
- [ ] Add Next button → proceed to Step 2
- [ ] Test validation

### 2.2 Registration Screen 2: Location (Required)
- [ ] Create District dropdown (load from data.txt or mock data)
- [ ] Create Divisional Secretarial (DS) area dropdown
- [ ] Implement dependent dropdown: DS areas update based on selected District
- [ ] Store Step 2 data locally
- [ ] Add Next button → proceed to Step 3
- [ ] Add Back button → return to Step 1

### 2.3 Registration Screen 3: Job Category (Optional)
- [ ] Build job category selection UI (multi-select)
- [ ] Load job categories from data.txt
- [ ] Allow deselection of categories
- [ ] Store Step 3 data locally
- [ ] Add Next button → proceed to Step 4
- [ ] Add Back button → return to Step 2
- [ ] Allow skip (optional screen)

### 2.4 Registration Screen 4: Skills (Optional)
- [ ] Build skills selection UI (multi-select)
- [ ] Populate skills based on selected job categories (Step 3)
- [ ] Show only skills relevant to user's job categories
- [ ] Store Step 4 data locally
- [ ] Add Next button → proceed to Step 5
- [ ] Add Back button → return to Step 3
- [ ] Allow skip (optional screen)

### 2.5 Registration Screen 5: Profile Photo (Optional)
- [ ] Implement image picker (image_picker package)
- [ ] Allow camera or gallery selection
- [ ] Crop/resize image (image_cropper package)
- [ ] Preview selected image
- [ ] Store Step 5 data locally
- [ ] Add Submit button → finalize registration
- [ ] Add Back button → return to Step 4
- [ ] Allow skip (optional screen)

### 2.6 Registration Completion
- [ ] Merge all registration data (Steps 1–5)
- [ ] Save user profile to Hive
- [ ] Store profile photo locally
- [ ] Auto-login user after registration
- [ ] Redirect to Dashboard (User Platform)
- [ ] Show success toast/message

---

## Phase 3: User Platform (Main App)

### 3.1 Platform Navigation Structure
- [ ] Implement bottom tab navigation (5+ tabs)
- [ ] Build persistent tab bar with icons
- [ ] Set up tab switching without losing state
- [ ] Support navigation within each tab

### 3.2 Dashboard Tab
- [ ] Add language switch button (top-right)
- [ ] Display welcome message ("Hello, [First Name]!")
- [ ] Show "Suitable Jobs Section" (jobs user can apply to)
- [ ] Implement job listing (title, employer name, category, brief description)
- [ ] Add "Apply" button per job
- [ ] Add floating action button (FAB) "Post Job" (bottom-right, sticky)
- [ ] Allow job filtering by category
- [ ] Show job details when tapped

### 3.3 Job Tab
- [ ] Display worker stats card:
  - Total completed jobs
  - Cancelled/removed jobs
  - Posted jobs count
  - Applied jobs count
- [ ] Show "Posted Jobs" list (jobs user posted)
- [ ] Show "Available Jobs" list (jobs user can apply to)
- [ ] Add filtering/sorting options
- [ ] Allow user to manage posted jobs
- [ ] Show application status for applied jobs

### 3.4 Job Management (Per Job)
- [ ] View job details
- [ ] For job poster:
  - [ ] View applied workers list
  - [ ] Message with workers
  - [ ] Assign worker to job
  - [ ] Remove worker from job
  - [ ] Edit job details
  - [ ] Delete job
  - [ ] Give review/rating to worker
- [ ] For job applicant:
  - [ ] View job details
  - [ ] Withdraw application
  - [ ] Contact poster

### 3.5 Job Post Screen
- [ ] Build job creation form:
  - [ ] Title input
  - [ ] Description input (text area)
  - [ ] Job category dropdown
  - [ ] Skills dropdown (multi-select, based on category)
  - [ ] Budget/payment input (optional)
  - [ ] Location/District (linked to user's location)
- [ ] Add "Post Job" button
- [ ] Validate form before submission
- [ ] Save job to Hive (offline-first)
- [ ] Show confirmation message
- [ ] Return to Dashboard

### 3.6 Message Tab
- [ ] Build community messaging UI:
  - [ ] Show list of communities (one per job category user selected)
  - [ ] Group messaging within each community
  - [ ] Message input and send functionality
  - [ ] Message history/scrollable list
- [ ] Build 1-on-1 chat UI:
  - [ ] Show list of connected users
  - [ ] Open chat on user select
  - [ ] Send/receive messages
  - [ ] Message timestamps
- [ ] Persist messages locally (Hive)
- [ ] Implement offline message queue (send when online)

### 3.7 Profile Tab
- [ ] Display user's public profile:
  - [ ] Profile photo
  - [ ] First name, Last name
  - [ ] Location (District, DS area)
  - [ ] Rank/rating (avg of reviews)
  - [ ] Total reviews count
  - [ ] Skills list (from registration)
- [ ] Show reviews/feedback received
- [ ] Link to edit profile (in Settings tab)

### 3.8 Search Tab
- [ ] Build search UI:
  - [ ] Search field (by worker name or NIC)
  - [ ] Search button or real-time filtering
- [ ] Display search results:
  - [ ] Worker tiles/cards
  - [ ] Show name, location, rank, skills
- [ ] Allow tapping result → view worker's public profile
- [ ] Show "Connect" button to send connection request

### 3.9 Settings Tab
- [ ] Add "Edit Basic Info" button → navigate to edit form
- [ ] Add "Update Skills" button → navigate to skills selection
- [ ] Add "Change PIN" button → PIN change form
- [ ] Show list of "Connection Requests" received
- [ ] Allow accept/reject connection requests
- [ ] Add "Sign Out" button
- [ ] Confirm before sign out

---

## Phase 4: Data & Backend Integration

### 4.1 Local Data Setup
- [ ] Load District/DS area data from data.txt
- [ ] Load job categories from data.txt
- [ ] Load skills from data.txt
- [ ] Seed Hive with initial data on first app launch
- [ ] Create mock user JSON database (simulate backend)

### 4.2 Backend API Endpoints (Mock)
- [ ] Create registered users database (JSON/Hive)
- [ ] Mock login endpoint (validate NIC + PIN)
- [ ] Mock registration endpoint (save user profile)
- [ ] Mock job posting endpoint
- [ ] Mock job listing endpoint (by category/location)
- [ ] Mock job application endpoint
- [ ] Mock user search endpoint (by name/NIC)
- [ ] Mock messaging endpoint (user lists, community lists, send message)
- [ ] Log all API calls to console

### 4.3 Offline-First Architecture
- [ ] Implement Hive boxes for:
  - [ ] Users (profile data, NIC as key)
  - [ ] Jobs (posted and applied)
  - [ ] Messages (chats and communities)
  - [ ] Connection requests
  - [ ] Reviews/ratings
- [ ] Add connectivity listener (via connectivity_plus)
- [ ] Queue unsent messages/requests when offline
- [ ] Sync queued data when connection restored
- [ ] Show offline indicator (optional badge on app bar)

---

## Phase 5: Multi-Language & Localization

### 5.1 Translation Files
- [ ] Complete English translations (app_strings, auth screens, platform screens, buttons, messages)
- [ ] Provide Sinhala (si.json) translations
- [ ] Provide Tamil (ta.json) translations
- [ ] Test all screens in all three languages
- [ ] Verify placeholder text displays correctly

### 5.2 UI Localization
- [ ] Ensure RTL support for translated text (if needed for Tamil/Sinhala)
- [ ] Test date/number formatting for all locales
- [ ] Verify images/icons are language-independent

---

## Phase 6: Testing & Deployment

### 6.1 Unit & Widget Tests
- [ ] Write tests for user model and validation functions
- [ ] Write tests for Hive local storage operations
- [ ] Write tests for localization provider
- [ ] Write widget tests for Login screen
- [ ] Write widget tests for Registration screens
- [ ] Write widget tests for Dashboard tab

### 6.2 Integration Tests
- [ ] Test complete registration flow
- [ ] Test login and session persistence
- [ ] Test job posting and listing
- [ ] Test messaging flow
- [ ] Test offline/online transitions

### 6.3 UI Polish
- [ ] Implement responsive layout (mobile, tablet)
- [ ] Add loading indicators (buttons, screens)
- [ ] Add error messages and validation feedback
- [ ] Add empty state screens (no jobs, no messages, etc.)
- [ ] Ensure consistent spacing, fonts, colors
- [ ] Add animations/transitions (optional but encouraged)

### 6.4 Android-Specific Fixes
- [ ] Remove `kotlin.incremental=false` workaround after Kotlin update
- [ ] Test on multiple Android versions (API 24+)
- [ ] Optimize asset loading
- [ ] Verify permissions (camera, gallery, storage)

### 6.5 Release Preparation
- [ ] Create app signing key
- [ ] Build release APK
- [ ] Test release build on device
- [ ] Create app icon and splash screen
- [ ] Write privacy policy and terms of service (if needed)
- [ ] Prepare for Google Play Store submission

---

## Phase 7: Enhancement & Documentation

### 7.1 Code Quality
- [ ] Set up Dart code analysis (flutter analyze)
- [ ] Enable CI/CD via GitHub Actions
- [ ] Add pre-commit hooks for formatting
- [ ] Write code comments for complex logic
- [ ] Create architecture documentation

### 7.2 Performance
- [ ] Profile app for slow screens
- [ ] Optimize Hive queries if needed
- [ ] Implement lazy loading for job lists
- [ ] Cache images locally

### 7.3 Future Features (Backlog)
- [ ] File uploads (portfolio items)
- [ ] Push notifications
- [ ] Video messaging
- [ ] Payment integration
- [ ] User verification (KYC)
- [ ] Admin panel

---

## Legend
- `[ ]` Not started
- `[x]` Completed
- `[-]` In progress

---

## Status Summary
**Total Tasks:** ~150+ actionable items  
**Completed:** 0  
**In Progress:** 0  
**Not Started:** 150+
