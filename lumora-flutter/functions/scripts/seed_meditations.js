const admin = require('firebase-admin');

const categoryConfig = {
  quick_1_min: { minutes: 1, label: '1 min', title: '1 Min Breathing Reset', count: 1 },
  '5_min': { minutes: 5, label: '5 min', titlePrefix: '5 Min Meditation', count: 6 },
  '10_min': { minutes: 10, label: '10 min', titlePrefix: '10 Min Meditation', count: 10 },
  '15_min': { minutes: 15, label: '15 min', titlePrefix: '15 Min Meditation', count: 6 },
  '20_min': { minutes: 20, label: '20 min', titlePrefix: '20 Min Meditation', count: 6 },
};

function buildTitle(category, sortOrder) {
  const config = categoryConfig[category];
  if (sortOrder === 1 && config.title) return config.title;
  return `${config.titlePrefix || config.title} ${sortOrder}`;
}

async function seedMeditations() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const db = admin.firestore();
  const batch = db.batch();
  
  let videoIndex = 1;

  for (const [category, config] of Object.entries(categoryConfig)) {
    for (let sortOrder = 1; sortOrder <= config.count; sortOrder++) {
      const docId = `${category}_${String(sortOrder).padStart(2, '0')}`;
      const videoFileName = `med_${videoIndex}.mp4`;
      
      batch.set(db.collection('meditations').doc(docId), {
        title: buildTitle(category, sortOrder),
        videoPath: `meditations/${videoFileName}`,
        category: category,
        durationMinutes: config.minutes,
        durationLabel: config.label,
        sortOrder,
        isActive: true,
        description: '',
        thumbnailUrl: '', // No thumbnails for now, the app will handle empty gracefully
        youtubeUrl: admin.firestore.FieldValue.delete(),
        youtubeVideoId: admin.firestore.FieldValue.delete(),
      }, { merge: true });
      
      videoIndex++;
    }
  }

  await batch.commit();
  console.log(`Seeded ${videoIndex - 1} meditation documents using Firebase Storage paths.`);
}

seedMeditations().catch((error) => {
  console.error(error);
  process.exit(1);
});
