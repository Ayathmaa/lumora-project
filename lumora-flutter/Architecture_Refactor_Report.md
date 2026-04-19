# Lumora Analytics & Architecture Refactor Report

After successfully migrating the heavy Gamification computations and Journey timeline streams to Firebase Cloud Functions, here are the remaining high-impact areas in the Lumora Flutter codebase that should be refactored to prioritize Cloud-native NoSQL architecture, performance scaling, and Firebase cost-reduction.

## 1. Merge `daily_moods` completely into `daily_analytics` payload
**The Problem**: Currently, `ChartDataService` reads two separate collections: `daily_analytics` (for CBT/ERP aggregates) and `daily_moods` (for the mood line graph). It matches their dates in Dart-memory.
**The Cloud Solution**: 
- Create a Cloud Function (`onMoodLogged`) that listens to the `users/{uid}/daily_moods/{date}` path.
- When a mood is saved, the Server atomically updates that exact day's `daily_analytics` document by appending `moodScore: score`.
- **Why?** Halves your Firestore Document reads on the Gamification screen and completely guarantees timezone timestamp synchronization in one payload.

## 2. GDPR User Data Deletion Engine (Auth Triggers)
**The Problem**: If a user deletes their Lumora account organically via Firebase Auth (or their anonymous session is purged), their deep-nested subcollections (`cbt_journal`, `erp_sessions`, `habit_trackers`, etc.) remain stuck indefinitely in the Firestore database.
**The Cloud Solution**:
- Introduce `functions.auth.user().onDelete(...)` in `index.ts`.
- The server will recursively run a massive batch-delete on `users/{uid}/*`.
- **Why?** Strictly required for App Store / Play Store data privacy guidelines and prevents permanent database storage bloat from uninstalled user sessions.

## 3. Server-Side Composite Filtering for AnoChat (firestore.rules)
**The Problem**: In `AnoChatService.postsStream()`, the app fetches `.limit(50)` globally, and *then* applies a Dart `where((p) => p.category == category)` filter. If the user clicks the "Small Win" category but the last 50 historical global posts were all "Struggling Today" vents, the Flutter UI will render 0 items—even if there are thousands of Small Win posts deeper in the database.
**The Cloud Solution**: 
- Create a Firestore Composite Index (`category` ASC, `createdAt` DESC).
- Switch the Flutter stream to `.where('category', isEqualTo: selectedCategory).limit(50)`.
- **Why?** Eliminates the bug of "empty feeds" when filtering, and avoids downloading 50 unused JSON documents into the phone memory only to discard them in Dart.

## 4. Thick-Client Pagination (History Lists Bloat)
**The Problem**: `JournalService.getHistory()` and `ErpTimerService.getSessionHistory()` return raw streams without any `limit()`. A dedicated user utilizing Lumora for 2 years will force the phone's CPU to download and parse ~1,400 documents instantly when they open the "Past Journals" screen.
**The Cloud Solution**: 
- Transition these heavy list streams into chunked pagination (`.limit(20)`) using `startAfterDocument`.
- **Why?** Protects Firebase Free Tier quotas. If 500 users open their journals, querying 10 documents each requires 5,000 DB reads. Querying 1,000 un-paginated documents each requires 500,000 DB reads and instantly triggers Firebase billing.

## 5. Journal Entry Auto-Numbering Concurrency
**The Problem**: In `journal_service.dart`, the app calls `await collectionRef.count().get()`, adds `1` to the result, and assigns it as `journalNumber`. If a user goes offline, writes 3 entries, and comes back online, all 3 might sync simultaneously and receive the exact same `journalNumber`.
**The Cloud Solution**: 
- Handle counting via a Cloud Function transaction that safely maintains a `totalJournals` counter on the user's `user_stats/gamification` doc and strictly sequentially numbers them.
- **Why?** Absolute data integrity completely immune to network dropouts and offline sync race-conditions. 

---

### Next Steps 🚀
Please review the five proposals above. Let me know which one(s) you would like me to architect and implement next (e.g. "Implement 1 and 3").
