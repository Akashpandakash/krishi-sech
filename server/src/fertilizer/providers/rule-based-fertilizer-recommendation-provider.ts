import type {
  FertilizerRecommendationInput,
  FertilizerRecommendationOutput,
  RecommendationLanguage,
} from './fertilizer-recommendation-provider.js';

type Copy = {
  method: string;
  morning: string;
  afterRain: string;
  precautions: string[];
  compost: string;
  mature: string;
};

const copy: Record<RecommendationLanguage, Copy> = {
  en: {
    method: 'Apply in two split doses around the root zone and mix lightly into moist soil.',
    morning: 'Apply in the early morning after light irrigation; avoid strong sun and wind.',
    afterRain: 'Wait until heavy rain has passed and the field is moist but not waterlogged.',
    precautions: ['Wear gloves and a mask.', 'Keep fertilizer away from stems and water sources.', 'Do not exceed the recommended dose.'],
    compost: 'Well-decomposed farmyard compost with neem cake',
    mature: 'No additional chemical fertilizer',
  },
  bn: {
    method: 'শিকড়ের চারপাশে দুই কিস্তিতে প্রয়োগ করে আর্দ্র মাটির সঙ্গে হালকা মিশিয়ে দিন।',
    morning: 'হালকা সেচের পর ভোরে প্রয়োগ করুন; কড়া রোদ ও জোর বাতাস এড়িয়ে চলুন।',
    afterRain: 'ভারী বৃষ্টি শেষ হওয়া পর্যন্ত অপেক্ষা করুন; জমি আর্দ্র কিন্তু জলাবদ্ধ নয় এমন সময় দিন।',
    precautions: ['গ্লাভস ও মাস্ক ব্যবহার করুন।', 'গাছের কাণ্ড ও জলাশয় থেকে সার দূরে রাখুন।', 'প্রস্তাবিত মাত্রা অতিক্রম করবেন না।'],
    compost: 'ভালোভাবে পচানো গোবর সার ও নিমখোল',
    mature: 'অতিরিক্ত রাসায়নিক সার প্রয়োজন নেই',
  },
  hi: {
    method: 'जड़ क्षेत्र के चारों ओर दो विभाजित खुराक में डालें और नम मिट्टी में हल्का मिला दें।',
    morning: 'हल्की सिंचाई के बाद सुबह जल्दी डालें; तेज धूप और हवा से बचें।',
    afterRain: 'तेज़ बारिश रुकने तक प्रतीक्षा करें; मिट्टी नम हो लेकिन जलभराव न हो।',
    precautions: ['दस्ताने और मास्क पहनें।', 'उर्वरक को तने और जल स्रोतों से दूर रखें।', 'अनुशंसित मात्रा से अधिक न डालें।'],
    compost: 'अच्छी तरह सड़ी गोबर खाद और नीम खली',
    mature: 'अतिरिक्त रासायनिक उर्वरक आवश्यक नहीं',
  },
};

export class RuleBasedFertilizerRecommendationProvider {
  recommend(input: FertilizerRecommendationInput): FertilizerRecommendationOutput {
    const text = copy[input.language];
    const stage = input.crop.growthStage;
    const crop = input.crop.cropName.toLowerCase();
    const base = this.stageRule(stage, crop, text);
    const soilFactor = input.crop.soilType === 'sandy' ? 0.85
      : input.crop.soilType === 'clay' ? 0.9 : 1;
    const rainLikely = (input.currentWeather?.rainProbabilityPercent ?? 0) >= 60;
    const recentFertilizer = input.lastFertilizer
      ? input.now.getTime() - input.lastFertilizer.occurredAt.getTime() < 14 * 86_400_000
      : false;
    const historySignals = input.fertilizerHistory.length + input.irrigationHistory.length;
    const confidence = Math.min(0.95, 0.62 + (input.currentWeather ? 0.08 : 0)
      + (historySignals > 0 ? 0.08 : 0) + (crop ? 0.05 : 0));
    const intervalDays = recentFertilizer ? 14 : base.intervalDays;
    const nextDate = new Date(input.now);
    nextDate.setUTCDate(nextDate.getUTCDate() + intervalDays);

    return {
      recommendedFertilizer: recentFertilizer ? text.mature : base.fertilizer,
      quantity: {
        value: recentFertilizer ? 0 : Math.round(base.quantity * soilFactor * 10) / 10,
        unit: 'kg',
        per: 'acre',
      },
      applicationMethod: text.method,
      bestApplicationTime: rainLikely ? text.afterRain : text.morning,
      safetyPrecautions: text.precautions,
      organicAlternative: text.compost,
      nextRecommendationDate: nextDate,
      confidence: Math.round(confidence * 100) / 100,
    };
  }

  private stageRule(stage: string, crop: string, text: Copy) {
    if (stage === 'maturity' || stage === 'harvested') {
      return { fertilizer: text.mature, quantity: 0, intervalDays: 21 };
    }
    if (stage === 'flowering' || stage === 'fruiting') {
      return { fertilizer: 'NPK 10-26-26', quantity: 25, intervalDays: 21 };
    }
    if (stage === 'vegetative' || stage === 'seedling') {
      return { fertilizer: crop.includes('rice') || crop.includes('paddy') ? 'Urea' : 'NPK 20-10-10', quantity: 30, intervalDays: 18 };
    }
    return { fertilizer: 'DAP', quantity: 35, intervalDays: 21 };
  }
}
