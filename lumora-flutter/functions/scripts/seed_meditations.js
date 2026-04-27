const admin = require('firebase-admin');

const meditationSources = [
  { category: 'quick_1_min', youtubeUrl: 'https://youtu.be/eZBa63NZbbE?si=u0iIkEh0aFMtWr2O' },
  { category: '5_min', youtubeUrl: 'https://youtu.be/vNy7s8GxUv0?si=mo_TaFXkOm0DGpvs' },
  { category: '5_min', youtubeUrl: 'https://youtu.be/qjzTH5e7_iU?si=ie3gQiJv-36m6emR' },
  { category: '5_min', youtubeUrl: 'https://youtu.be/aBNBNloeWxg?si=LNFBW3DTR6P7rwDP' },
  { category: '5_min', youtubeUrl: 'https://youtu.be/xelhINErEDc?si=UPzkTNEB8vWyx6IV' },
  { category: '5_min', youtubeUrl: 'https://youtu.be/2K4T9HmEhWE?si=3Cs3cd90c6Zln4fi' },
  { category: '5_min', youtubeUrl: 'https://youtu.be/OjtcI3vWnpk?si=pHzCml1O3Xqh6YEH' },
  { category: '10_min', youtubeUrl: 'https://youtu.be/1iOUQHCes6Q?si=6g6zGK6JHSdAkb6J' },
  { category: '10_min', youtubeUrl: 'https://youtu.be/O-jcmB6BUvY?si=DiMG2Ia53K0d1YWN' },
  { category: '10_min', youtubeUrl: 'https://youtu.be/hnPRRJaziHg?si=jBEkc6qDkzMJPErJ' },
  { category: '10_min', youtubeUrl: 'https://youtu.be/cWCpr38Dm9M?si=wcTCgPEzlacQhY_f' },
  { category: '10_min', youtubeUrl: 'https://youtu.be/tMc9uxDYGJY?si=kHWiuMdQr4jeZoQp' },
  { category: '10_min', youtubeUrl: 'https://youtu.be/HfVXwA6L154?si=hOTk338XhpFNMley' },
  { category: '10_min', youtubeUrl: 'https://youtu.be/XGmoBdZpVqY?si=snyogqCbsCEe-ROE' },
  { category: '10_min', youtubeUrl: 'https://youtu.be/o_SHRA0oxRQ?si=RaGf_lFzSWF72bqB' },
  { category: '10_min', youtubeUrl: 'https://youtu.be/xv-ejEOogaA?si=WD745B7oSP6O-xeK' },
  { category: '10_min', youtubeUrl: 'https://youtu.be/LLeqY9ingRY?si=NZ55nbycpvbRuCNb' },
  { category: '15_min', youtubeUrl: 'https://youtu.be/zdFWA4dp3zk?si=icOkpkIikQGp4Rh_' },
  { category: '15_min', youtubeUrl: 'https://youtu.be/xXQ2o6IJ2bg?si=IW1w2sOkC2gmjTGx' },
  { category: '15_min', youtubeUrl: 'https://youtu.be/1YdKRdxZ9uI?si=6ad-NZQRJB25lFB4' },
  { category: '15_min', youtubeUrl: 'https://youtu.be/E6Svf01Ej40?si=dGrzNNNyGi3rlOmy' },
  { category: '15_min', youtubeUrl: 'https://youtu.be/C5MaztWGaN0?si=wztYpqRNRq2dXO5x' },
  { category: '15_min', youtubeUrl: 'https://youtu.be/39h_j-RZiuM?si=9VKmw7lyw0oUxO_n' },
  { category: '20_min', youtubeUrl: 'https://youtu.be/kwPOT0tOENo?si=nIIceg3XLsgh_jYi' },
  { category: '20_min', youtubeUrl: 'https://youtu.be/9fr6geQtd88?si=ujPXwM2vDSJYMZiH' },
  { category: '20_min', youtubeUrl: 'https://youtu.be/GTdEJwVOxg0?si=R2lLr7hN4Y8rGhBf' },
  { category: '20_min', youtubeUrl: 'https://youtu.be/g0jfhRcXtLQ?si=72L0kY1_akXHy3C8' },
  { category: '20_min', youtubeUrl: 'https://youtu.be/_SU1QQhCDcs?si=5MQ0bLfBdj_wHa1o' },
  { category: '20_min', youtubeUrl: 'https://youtu.be/Mb5MR1OSTEc?si=mVqQfQLx2cH1I43T' },
];

const categoryConfig = {
  quick_1_min: { minutes: 1, label: '1 min', title: '1 Min Breathing Reset' },
  '5_min': { minutes: 5, label: '5 min', titlePrefix: '5 Min Meditation' },
  '10_min': { minutes: 10, label: '10 min', titlePrefix: '10 Min Meditation' },
  '15_min': { minutes: 15, label: '15 min', titlePrefix: '15 Min Meditation' },
  '20_min': { minutes: 20, label: '20 min', titlePrefix: '20 Min Meditation' },
};

function extractYoutubeVideoId(url) {
  const parsed = new URL(url);
  if (parsed.hostname.includes('youtu.be')) {
    return parsed.pathname.replace(/^\/+/, '').split('/')[0];
  }

  if (parsed.searchParams.get('v')) {
    return parsed.searchParams.get('v');
  }

  const segments = parsed.pathname.split('/').filter(Boolean);
  if (segments[0] === 'embed' || segments[0] === 'shorts') {
    return segments[1];
  }

  throw new Error(`Could not extract YouTube video id from ${url}`);
}

function buildTitle(category, sortOrder) {
  const config = categoryConfig[category];
  if (config.title) return config.title;
  return `${config.titlePrefix} ${sortOrder}`;
}

function buildThumbnailUrl(videoId) {
  return `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`;
}

async function seedMeditations() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const db = admin.firestore();
  const batch = db.batch();
  const counters = {};

  for (const source of meditationSources) {
    counters[source.category] = (counters[source.category] || 0) + 1;
    const sortOrder = counters[source.category];
    const config = categoryConfig[source.category];
    const youtubeVideoId = extractYoutubeVideoId(source.youtubeUrl);
    const docId = `${source.category}_${String(sortOrder).padStart(2, '0')}`;

    batch.set(db.collection('meditations').doc(docId), {
      title: buildTitle(source.category, sortOrder),
      youtubeUrl: source.youtubeUrl,
      youtubeVideoId,
      category: source.category,
      durationMinutes: config.minutes,
      durationLabel: config.label,
      sortOrder,
      isActive: true,
      description: '',
      thumbnailUrl: buildThumbnailUrl(youtubeVideoId),
    }, { merge: true });
  }

  await batch.commit();
  console.log(`Seeded ${meditationSources.length} meditation documents.`);
}

seedMeditations().catch((error) => {
  console.error(error);
  process.exit(1);
});
