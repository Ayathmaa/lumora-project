import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ── 1. AnoChat Content Moderation ─────────────────────────────────────────
// Compound phrases to avoid flagging legitimate mental health discussion.
const FLAGGED_PHRASES = [
  "kill myself",
  "end my life",
  "want to die",
  "suicide",
  "self-harm",
  "self harm",
  "hurt myself",
  "harm myself",
  "cut myself",
  "ending it all",
  "not worth living",
];

export const moderateAnoChatPost = functions.firestore
  .document("anoPosts/{postId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data || !data.content) return null;

    const content = data.content.toLowerCase();
    const isFlagged = FLAGGED_PHRASES.some((phrase) => content.includes(phrase));

    if (isFlagged) {
      console.log(`Post ${context.params.postId} flagged for moderation.`);
      // Hide from stream natively and mark for admin review
      return snap.ref.update({
        requiresReview: true,
        isHidden: true,
      });
    }
    return null;
  });

// ── 2. AnoChat Reaction Integrity & Counter Aggregation ───────────────────
export const aggregateAnoChatReactions = functions.firestore
  .document("users/{uid}/anoReactions/{postId}")
  .onWrite(async (change, context) => {
    const { postId } = context.params;
    const postRef = db.collection("anoPosts").doc(postId);

    const beforeData = change.before.data();
    const afterData = change.after.data();

    const beforeType = beforeData ? beforeData.type : null;
    const afterType = afterData ? afterData.type : null;

    // No change in reaction
    if (beforeType === afterType) return null;

    return db.runTransaction(async (tx) => {
      const postSnap = await tx.get(postRef);
      if (!postSnap.exists) return null;

      const updates: Record<string, admin.firestore.FieldValue> = {};

      // Remove previous reaction if it existed
      if (beforeType) {
        updates[`reactionCounts.${beforeType}`] = admin.firestore.FieldValue.increment(-1);
      }

      // Add new reaction if it exists (not deleted)
      if (afterType) {
        updates[`reactionCounts.${afterType}`] = admin.firestore.FieldValue.increment(1);
      }

      if (Object.keys(updates).length > 0) {
        tx.update(postRef, updates);
      }
      return null;
    });
  });

// ── 3. Gamification System (XP & Streaks) ─────────────────────────────────

const BASE_XP = {
  JOURNAL: 10,
  ERP: 15,
  BREATHING: 5,
  HABIT: 5,
};

async function awardGamificationXP(uid: string, baseXP: number) {
  const statsRef = db.collection('users').doc(uid).collection('user_stats').doc('gamification');

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(statsRef);
    let currentXP = 0;
    let currentStreak = 0;
    let highestStreak = 0;
    let lastActivityDate = '';

    if (snap.exists) {
      const data = snap.data();
      if (data) {
        currentXP = data.xp || 0;
        currentStreak = data.currentStreak || 0;
        highestStreak = data.highestStreak || 0;
        lastActivityDate = data.lastActivityDate || '';
      }
    }

    const todayDate = new Date();
    const todayStr = todayDate.toISOString().split('T')[0];

    if (lastActivityDate) {
      const todayZero = new Date(`${todayStr}T00:00:00Z`);
      const lastZero = new Date(`${lastActivityDate}T00:00:00Z`);
      const diffDays = Math.round((todayZero.getTime() - lastZero.getTime()) / 86400000);

      if (diffDays === 1) {
        // Continuous daily streak
        currentStreak += 1;
      } else if (diffDays > 1) {
        // Streak broken
        currentStreak = 1;
      } else if (diffDays === 0 && currentStreak === 0) {
         currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    if (currentStreak > highestStreak) {
      highestStreak = currentStreak;
    }

    // Apply multiplier/bonus for having a streak
    const streakBonus = currentStreak >= 2 ? currentStreak * 2 : 0;
    currentXP += (baseXP + streakBonus);

    tx.set(statsRef, {
      xp: currentXP,
      currentStreak,
      highestStreak,
      lastActivityDate: todayStr,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  });
}

// 3a. Journal XP
export const onJournalCreated = functions.firestore
  .document('users/{uid}/cbt_journal/{entryId}')
  .onCreate(async (snap, context) => {
    return awardGamificationXP(context.params.uid, BASE_XP.JOURNAL);
  });

// 3b. ERP Session XP
export const onErpSessionCreated = functions.firestore
  .document('users/{uid}/erp_sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    // Only award XP if complete? The prompt says 'every completed erp session should increase xp'
    // The dart file uses 'session_complete' (int: 1 for complete)
    if (data && (data.session_complete === 1 || data.session_complete === true)) {
      return awardGamificationXP(context.params.uid, BASE_XP.ERP);
    }
    return null;
  });

// 3c. Breathing Session XP
export const onBreathingSessionCreated = functions.firestore
  .document('users/{uid}/breathing_sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    // The prompt says 'every complete breathing exercise session'
    if (data && data.completed === true) {
      return awardGamificationXP(context.params.uid, BASE_XP.BREATHING);
    }
    return null;
  });

// 3d. Habit Freedom XP & Streak Calculation (App transferred to Cloud)
export const onHabitMarkedDay = functions.firestore
  .document('users/{uid}/habit_trackers/{habitId}')
  .onUpdate(async (change, context) => {
    const beforeDays = change.before.data()?.markedDates || [];
    const afterDays = change.after.data()?.markedDates || [];

    // Did the user mark a new day?
    if (afterDays.length > beforeDays.length) {
      // Award Gamification XP for marking a new habit
      await awardGamificationXP(context.params.uid, BASE_XP.HABIT);

      // We ALSO calculate the inner habit streak directly here.
      // After array is already updated in Firestore.
      if (afterDays.length > 0) {
        // Sort dates to compute streak properly
        const sortedDates = [...afterDays].sort();
        
        let currentStreak = 1;
        let longestStreak = 1;
        
        // Compute longest
        let run = 1;
        for (let i = 1; i < sortedDates.length; i++) {
          const d1 = new Date(`${sortedDates[i-1]}T00:00:00Z`);
          const d2 = new Date(`${sortedDates[i]}T00:00:00Z`);
          const diff = Math.round((d2.getTime() - d1.getTime()) / 86400000);
          
          if (diff === 1) {
            run += 1;
          } else if (diff > 1) {
            run = 1;
          }
          if (run > longestStreak) { longestStreak = run; }
        }
        
        // Compute current
        for (let i = sortedDates.length - 1; i > 0; i--) {
          const d1 = new Date(`${sortedDates[i-1]}T00:00:00Z`);
          const d2 = new Date(`${sortedDates[i]}T00:00:00Z`);
          const diff = Math.round((d2.getTime() - d1.getTime()) / 86400000);
          if (diff === 1) {
            currentStreak += 1;
          } else {
            break;
          }
        }
        
        // Determine if current streak is broken (based on UTC relative to today, or just relative to local 'dateKey')
        const latestMarkedStr = sortedDates[sortedDates.length - 1];
        const latestMarked = new Date(`${latestMarkedStr}T00:00:00Z`);
        const today = new Date();
        const todayZero = new Date(`${today.toISOString().split('T')[0]}T00:00:00Z`);
        const diffFromToday = Math.round((todayZero.getTime() - latestMarked.getTime()) / 86400000);
        
        if (diffFromToday > 1) {
           currentStreak = 0;
        }

        // Avoid infinite loops in onUpdate:
        // Only write back to document if the stats actually changed.
        const prevCurrent = change.after.data()?.currentStreak || 0;
        const prevLongest = change.after.data()?.longestStreak || 0;
        const prevTotal = change.after.data()?.totalMarkedDays || 0;

        if (currentStreak !== prevCurrent || longestStreak !== prevLongest || sortedDates.length !== prevTotal) {
           return change.after.ref.update({
             currentStreak,
             longestStreak,
             totalMarkedDays: sortedDates.length
           });
        }
      }
    }
    return null;
  });

