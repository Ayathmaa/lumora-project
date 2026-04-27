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

// ── 3. Gamification System (XP & Streaks) & Timeline Generation ───────────

const BASE_XP = {
  JOURNAL: 10,
  ERP: 15,
  BREATHING: 5,
  HABIT: 5,
};

async function logTimelineEvent(uid: string, eventId: string, timestamp: Date, type: string, title: string, detail: string) {
  const ref = db.collection('users').doc(uid).collection('timeline_events').doc(eventId);
  await ref.set({
    date: admin.firestore.Timestamp.fromDate(timestamp),
    type,
    title,
    detail,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
}

async function awardGamificationXP(uid: string, baseXP: number, moduleType: 'journal' | 'erp' | 'breathing' | 'habit') {
  const statsRef = db.collection('users').doc(uid).collection('user_stats').doc('gamification');

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(statsRef);
    let currentXP = 0;
    
    // Global
    let currentStreak = 0;
    let highestStreak = 0;
    let lastActivityDate = '';
    
    // Module level
    let moduleStreaks: Record<string, number> = {
      journal: 0, erp: 0, breathing: 0, habit: 0
    };
    let moduleLastActivityDates: Record<string, string> = {};

    if (snap.exists) {
      const data = snap.data();
      if (data) {
        currentXP = data.xp || 0;
        currentStreak = data.currentStreak || 0;
        highestStreak = data.highestStreak || 0;
        lastActivityDate = data.lastActivityDate || '';
        moduleStreaks = data.moduleStreaks || moduleStreaks;
        moduleLastActivityDates = data.moduleLastActivityDates || moduleLastActivityDates;
      }
    }

    const todayDate = new Date();
    const todayStr = todayDate.toISOString().split('T')[0];

    // -- Update Global Streak --
    if (lastActivityDate) {
      const todayZero = new Date(`${todayStr}T00:00:00Z`);
      const lastZero = new Date(`${lastActivityDate}T00:00:00Z`);
      const diffDays = Math.round((todayZero.getTime() - lastZero.getTime()) / 86400000);

      if (diffDays === 1) {
        currentStreak += 1;
      } else if (diffDays > 1) {
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

    // -- Update Module Specific Streak --
    let modStreak = moduleStreaks[moduleType] || 0;
    const modLastDate = moduleLastActivityDates[moduleType] || '';
    
    if (modLastDate) {
      const todayZero = new Date(`${todayStr}T00:00:00Z`);
      const lastZero = new Date(`${modLastDate}T00:00:00Z`);
      const diffDays = Math.round((todayZero.getTime() - lastZero.getTime()) / 86400000);

      if (diffDays === 1) {
        modStreak += 1;
      } else if (diffDays > 1) {
        modStreak = 1;
      } else if (diffDays === 0 && modStreak === 0) {
        modStreak = 1;
      }
    } else {
      modStreak = 1;
    }

    moduleStreaks[moduleType] = modStreak;
    moduleLastActivityDates[moduleType] = todayStr;

    // -- Update XP --
    const streakBonus = currentStreak >= 2 ? currentStreak * 2 : 0;
    currentXP += (baseXP + streakBonus);

    tx.set(statsRef, {
      xp: currentXP,
      currentStreak,
      highestStreak,
      lastActivityDate: todayStr,
      moduleStreaks,
      moduleLastActivityDates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  });
}

// 3a. Journal XP
export const onJournalCreated = functions.firestore
  .document('users/{uid}/cbt_journal/{entryId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;
    
    const preAnx = data.preAnxietyLevel ?? '?';
    const postAnx = data.postAnxietyLevel ?? '?';
    const ts = data.createdAt ? data.createdAt.toDate() : new Date();

    await logTimelineEvent(
      context.params.uid, 
      context.params.entryId, 
      ts, 
      'Journal', 
      `Journal Entry #${data.journalNumber ?? '?'}`,
      `Pre-anxiety: ${preAnx}/10 | Post-anxiety: ${postAnx}/10`
    );

    return awardGamificationXP(context.params.uid, BASE_XP.JOURNAL, 'journal');
  });

// 3b. ERP Session XP
export const onErpSessionCreated = functions.firestore
  .document('users/{uid}/erp_sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (data && (data.session_complete === 1 || data.session_complete === true)) {
      const ts = data.timestamp ? data.timestamp.toDate() : new Date();
      await logTimelineEvent(
        context.params.uid,
        context.params.sessionId,
        ts,
        'ERP',
        'ERP Session',
        `${data.duration_mins ?? 0} mins (Complete)`
      );
      
      return awardGamificationXP(context.params.uid, BASE_XP.ERP, 'erp');
    }
    return null;
  });

// 3c. Breathing Session XP
export const onBreathingSessionCreated = functions.firestore
  .document('users/{uid}/breathing_sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (data && data.completed === true) {
      const ts = data.timestamp ? data.timestamp.toDate() : new Date();
      await logTimelineEvent(
        context.params.uid,
        context.params.sessionId,
        ts,
        'Breathing',
        `Breathing: ${data.exerciseType ?? 'Exercise'}`,
        `${data.durationSeconds ?? 0} secs`
      );

      return awardGamificationXP(context.params.uid, BASE_XP.BREATHING, 'breathing');
    }
    return null;
  });

// 3d. Habit Freedom XP, Timeline Generation & Legacy Streak Calculation
export const onHabitMarkedDay = functions.firestore
  .document('users/{uid}/habit_trackers/{habitId}')
  .onUpdate(async (change, context) => {
    const beforeDays = change.before.data()?.markedDates || [];
    const afterDays = change.after.data()?.markedDates || [];

    if (afterDays.length > beforeDays.length) {
       // We marked a new day! 
       const newlyMarkedDayStr = afterDays[afterDays.length - 1]; // "2026-04-19"
       const habitName = change.after.data()?.name || 'Habit';
       
       // Use noon for the timeline timestamp to stay consistent with past Logic
       const dateObj = new Date(`${newlyMarkedDayStr}T12:00:00.000Z`);

       await logTimelineEvent(
         context.params.uid,
         `${context.params.habitId}_${newlyMarkedDayStr}`, // unique ID per day marked
         dateObj,
         'Habit',
         'Habit Kept Free',
         habitName
       );

      await awardGamificationXP(context.params.uid, BASE_XP.HABIT, 'habit');

      // We ALSO calculate the inner habit streak directly here.
      // After array is already updated in Firestore.
      if (afterDays.length > 0) {
        const sortedDates = [...afterDays].sort();
        let currentStreak = 1;
        let longestStreak = 1;
        
        let run = 1;
        for (let i = 1; i < sortedDates.length; i++) {
          const d1 = new Date(`${sortedDates[i-1]}T00:00:00Z`);
          const d2 = new Date(`${sortedDates[i]}T00:00:00Z`);
          const diff = Math.round((d2.getTime() - d1.getTime()) / 86400000);
          
          if (diff === 1) { run += 1; } 
          else if (diff > 1) { run = 1; }
          if (run > longestStreak) { longestStreak = run; }
        }
        
        for (let i = sortedDates.length - 1; i > 0; i--) {
          const d1 = new Date(`${sortedDates[i-1]}T00:00:00Z`);
          const d2 = new Date(`${sortedDates[i]}T00:00:00Z`);
          const diff = Math.round((d2.getTime() - d1.getTime()) / 86400000);
          if (diff === 1) { currentStreak += 1; } 
          else { break; }
        }
        
        const latestMarkedStr = sortedDates[sortedDates.length - 1];
        const latestMarked = new Date(`${latestMarkedStr}T00:00:00Z`);
        const todayZero = new Date(`${new Date().toISOString().split('T')[0]}T00:00:00Z`);
        const diffFromToday = Math.round((todayZero.getTime() - latestMarked.getTime()) / 86400000);
        if (diffFromToday > 1) { currentStreak = 0; }

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

// ── 4. Data Aggregation for Analytics (Optimized Dashboard) ───────────────

/**
 * Calculates the average 'Anxiety Remaining %' for a specific date 
 * across both CBT Journals and ERP Sessions, then saves it to a single 
 * aggregated daily document to save client reads.
 */
async function updateDailyAnxietyAggregate(uid: string, targetDateStr: string, dateObj: Date) {
  // If targeting a local dateKey, we aggregate by targetDateStr
  // However, we must also catch old documents that might only have UTC timestamps.
  // The absolute safest enterprise approach is to query BOTH ways, then merge uniqueness using Document ID.
  
  const startOfDay = new Date(`${targetDateStr}T00:00:00.000Z`);
  const endOfDay = new Date(`${targetDateStr}T23:59:59.999Z`);

  let totalPercentage = 0;
  let count = 0;
  const processedDocs = new Set<string>();

  // 1) Fetch CBT Journals
  // a) Query by the new localized dateKey
  const journalsDateKeySnap = await db.collection(`users/${uid}/cbt_journal`)
    .where('dateKey', '==', targetDateStr)
    .get();
    
  // b) Query by old legacy UTC boundary (fallback for old docs missing dateKey)
  const journalsUtcSnap = await db.collection(`users/${uid}/cbt_journal`)
    .where('createdAt', '>=', startOfDay)
    .where('createdAt', '<=', endOfDay)
    .get();

  const processJournalDoc = (doc: FirebaseFirestore.DocumentSnapshot) => {
    if (processedDocs.has(doc.id)) return;
    processedDocs.add(doc.id);
    const data = doc.data();
    if (!data) return;
    
    // Only count old UTC docs if they haven't explicitly set a different dateKey
    if (data.dateKey && data.dateKey !== targetDateStr) return;

    if (typeof data.preAnxietyLevel === 'number' && typeof data.postAnxietyLevel === 'number') {
      const pre = data.preAnxietyLevel;
      const post = data.postAnxietyLevel;
      const percentage = pre > 0 ? (post / pre) * 100.0 : 0.0;
      totalPercentage += percentage;
      count++;
    }
  };

  journalsDateKeySnap.forEach(processJournalDoc);
  journalsUtcSnap.forEach(processJournalDoc);

  // 2) Fetch ERP Sessions
  const erpsDateKeySnap = await db.collection(`users/${uid}/erp_sessions`)
    .where('dateKey', '==', targetDateStr)
    .get();

  const erpsUtcSnap = await db.collection(`users/${uid}/erp_sessions`)
    .where('timestamp', '>=', startOfDay)
    .where('timestamp', '<=', endOfDay)
    .get();

  const processErpDoc = (doc: FirebaseFirestore.DocumentSnapshot) => {
    if (processedDocs.has(doc.id)) return;
    processedDocs.add(doc.id);
    const data = doc.data();
    if (!data) return;
    
    if (data.dateKey && data.dateKey !== targetDateStr) return;

    if ((data.session_complete === 1 || data.session_complete === true) && 
        typeof data.pre_anxiety === 'number' && 
        typeof data.post_anxiety === 'number') {
      const pre = data.pre_anxiety;
      const post = data.post_anxiety;
      const percentage = pre > 0 ? (post / pre) * 100.0 : 0.0;
      totalPercentage += percentage;
      count++;
    }
  };

  erpsDateKeySnap.forEach(processErpDoc);
  erpsUtcSnap.forEach(processErpDoc);

  const analyticsRef = db.collection(`users/${uid}/daily_analytics`).doc(targetDateStr);
  
  if (count > 0) {
    const dailyAverage = totalPercentage / count;
    await analyticsRef.set({
      dateStr: targetDateStr,
      timestamp: admin.firestore.Timestamp.fromDate(startOfDay), // Midnight fallback
      anxietyRemainingPercent: dailyAverage,
      sessionsCount: count,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  } else {
    await analyticsRef.delete().catch(() => {}); 
  }
}

export const aggregateJournalAnxiety = functions.firestore
  .document('users/{uid}/cbt_journal/{entryId}')
  .onWrite(async (change, context) => {
    const data = change.after.exists ? change.after.data() : change.before.data();
    if (!data) return null;
    
    let targetDateStr = data.dateKey;
    const dateObj = data.createdAt ? data.createdAt.toDate() : new Date();
    
    if (!targetDateStr) {
      targetDateStr = dateObj.toISOString().split('T')[0];
    }
    
    await updateDailyAnxietyAggregate(context.params.uid, targetDateStr, dateObj);
    return null;
  });

export const aggregateErpAnxiety = functions.firestore
  .document('users/{uid}/erp_sessions/{sessionId}')
  .onWrite(async (change, context) => {
    const data = change.after.exists ? change.after.data() : change.before.data();
    if (!data) return null;
    
    let targetDateStr = data.dateKey;
    const dateObj = data.timestamp ? data.timestamp.toDate() : new Date();
    
    if (!targetDateStr) {
      targetDateStr = dateObj.toISOString().split('T')[0];
    }
    
    await updateDailyAnxietyAggregate(context.params.uid, targetDateStr, dateObj);
    return null;
  });

export const onMoodLogged = functions.firestore
  .document('users/{uid}/daily_moods/{dateKey}')
  .onWrite(async (change, context) => {
    const { uid, dateKey } = context.params;
    const analyticsRef = db.collection(`users/${uid}/daily_analytics`).doc(dateKey);

    if (!change.after.exists) {
      // Mood was deleted
      // We use merge: true so we don't accidentally delete anxiety info if it exists.
      await analyticsRef.set({
        moodScore: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      return null;
    }

    const data = change.after.data();
    if (!data) return null;

    const startOfDay = new Date(`${dateKey}T00:00:00.000Z`);

    // Merge the daily mood score into the daily analytics document!
    await analyticsRef.set({
      dateStr: dateKey,
      timestamp: admin.firestore.Timestamp.fromDate(startOfDay), // Safety timestamp
      moodScore: data.score,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    return null;
  });

// Task 2: GDPR User Data Deletion Engine (Auth Triggers)
// Automatically purges all deeply-nested subcollections when a user is deleted from Firebase Auth.
async function deleteCollectionInBatches(collectionRef: FirebaseFirestore.CollectionReference) {
  const batchSize = 300;
  let snapshot = await collectionRef.limit(batchSize).get();
  while (snapshot.size > 0) {
    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    snapshot = await collectionRef.limit(batchSize).get();
  }
}

export const onUserAccountDeleted = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const userRef = db.collection('users').doc(uid);
  
  try {
    // 1. Fetch all subcollections dynamically (cbt_journal, erp_sessions, daily_analytics, etc.)
    const subcollections = await userRef.listCollections();
    
    // 2. Delete all documents inside each subcollection in 300-doc batches
    for (const subcol of subcollections) {
      await deleteCollectionInBatches(subcol);
    }
    
    // 3. Delete the parent user document itself
    await userRef.delete();
    console.log(`Successfully purged all GDPR user data for UID: ${uid}`);
  } catch (error) {
    console.error(`Fatal error purging user data for UID ${uid}:`, error);
  }
});

// ── 5. Partner / Pairing Flow ─────────────────────────────────────────────

export const searchUsers = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  const searchTerm = data.username?.trim().toLowerCase();
  if (!searchTerm) return [];

  // Prefix search for usernames
  const snapshot = await db.collection("users")
    .where("username", ">=", searchTerm)
    .where("username", "<=", searchTerm + "\uf8ff")
    .limit(10)
    .get();

  const results: any[] = [];
  snapshot.forEach(doc => {
    if (doc.id === context.auth?.uid) return; // exclude self
    const userData = doc.data();
    results.push({
      uid: doc.id,
      username: userData.username,
      displayName: userData.displayName || "",
      avatarUrl: userData.avatarUrl || "",
    });
  });

  return results;
});

export const sendPartnerInvite = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  const senderId = context.auth.uid;
  const receiverId = data.receiverId;

  if (!receiverId) throw new functions.https.HttpsError("invalid-argument", "Receiver ID is required.");
  if (senderId === receiverId) throw new functions.https.HttpsError("invalid-argument", "Cannot invite yourself.");

  const receiverDoc = await db.collection("users").doc(receiverId).get();
  if (!receiverDoc.exists) throw new functions.https.HttpsError("not-found", "Receiver not found.");

  // Check if there is already a pending invite
  const existingInvites = await db.collection("partner_invites")
    .where("senderId", "==", senderId)
    .where("receiverId", "==", receiverId)
    .where("status", "==", "pending")
    .get();

  if (!existingInvites.empty) {
    throw new functions.https.HttpsError("already-exists", "An invite is already pending.");
  }

  // Check if they are already partners
  const senderDoc = await db.collection("users").doc(senderId).get();
  if (senderDoc.data()?.partnerId === receiverId) {
    throw new functions.https.HttpsError("already-exists", "You are already partners.");
  }

  const inviteData = {
    senderId,
    receiverId,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const docRef = await db.collection("partner_invites").add(inviteData);
  return { id: docRef.id, ...inviteData };
});

export const acceptPartnerInvite = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  const uid = context.auth.uid;
  const inviteId = data.inviteId;

  if (!inviteId) throw new functions.https.HttpsError("invalid-argument", "Invite ID is required.");

  return db.runTransaction(async (tx) => {
    const inviteRef = db.collection("partner_invites").doc(inviteId);
    const inviteDoc = await tx.get(inviteRef);

    if (!inviteDoc.exists) throw new functions.https.HttpsError("not-found", "Invite not found.");
    
    const inviteData = inviteDoc.data()!;
    if (inviteData.receiverId !== uid) {
      throw new functions.https.HttpsError("permission-denied", "You can only accept invites sent to you.");
    }
    if (inviteData.status !== "pending") {
      throw new functions.https.HttpsError("failed-precondition", "Invite is no longer pending.");
    }

    const senderId = inviteData.senderId;

    const senderRef = db.collection("users").doc(senderId);
    const receiverRef = db.collection("users").doc(uid);

    // Initial partner sharing preferences
    const defaultPreferences = {
      shareJournal: false,
      shareErpProgress: false,
      shareHabits: false,
    };

    tx.update(senderRef, { 
      partnerId: uid,
      partnerPreferences: defaultPreferences
    });
    tx.update(receiverRef, { 
      partnerId: senderId,
      partnerPreferences: defaultPreferences
    });

    tx.update(inviteRef, { 
      status: "accepted",
      acceptedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Also invalidate any other pending requests between the two or from others if we only allow 1 partner
    return { success: true, partnerId: senderId };
  });
});

export const removePartner = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  const uid = context.auth.uid;

  return db.runTransaction(async (tx) => {
    const userRef = db.collection("users").doc(uid);
    const userDoc = await tx.get(userRef);

    if (!userDoc.exists) throw new functions.https.HttpsError("not-found", "User not found.");
    
    const partnerId = userDoc.data()?.partnerId;
    if (!partnerId) {
      throw new functions.https.HttpsError("failed-precondition", "You do not have a partner to remove.");
    }

    const partnerRef = db.collection("users").doc(partnerId);

    // Remove from self
    tx.update(userRef, {
      partnerId: admin.firestore.FieldValue.delete(),
      partnerPreferences: admin.firestore.FieldValue.delete()
    });

    // Remove from partner (using set / update with condition if possible, but blind update in tx is fine as long as they are partnered)
    // Avoid failing if partner deleted account
    const partnerDoc = await tx.get(partnerRef);
    if (partnerDoc.exists && partnerDoc.data()?.partnerId === uid) {
      tx.update(partnerRef, {
        partnerId: admin.firestore.FieldValue.delete(),
        partnerPreferences: admin.firestore.FieldValue.delete()
      });
    }

    return { success: true };
  });
});
