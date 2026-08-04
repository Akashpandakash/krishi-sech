import type {
  IrrigationLanguage,
  IrrigationRecommendationInput,
  IrrigationRecommendationOutput,
  IrrigationRecommendationProvider,
} from './irrigation-recommendation-provider.js';

type Copy = {
  morning: string;
  methods: Record<string, string>;
  rain: string;
  recent: string;
  required: string;
  harvested: string;
};

const copy: Record<IrrigationLanguage, Copy> = {
  en: {
    morning: 'Early morning before strong sunlight',
    methods: { drip: 'Drip irrigation', sprinkler: 'Sprinkler irrigation', flood: 'Controlled flood irrigation', rainFed: 'Supplemental irrigation', manual: 'Root-zone manual irrigation' },
    rain: 'Irrigation is not required now because significant rain is forecast.',
    recent: 'Irrigation is not required because the crop was irrigated recently.',
    required: 'Irrigation is recommended based on crop stage, soil water retention, weather and irrigation history.',
    harvested: 'No irrigation is required for a harvested crop.',
  },
  bn: {
    morning: 'কড়া রোদ ওঠার আগে ভোরবেলা',
    methods: { drip: 'ড্রিপ সেচ', sprinkler: 'স্প্রিংকলার সেচ', flood: 'নিয়ন্ত্রিত প্লাবন সেচ', rainFed: 'সম্পূরক সেচ', manual: 'শিকড় অঞ্চলে হাতে সেচ' },
    rain: 'উল্লেখযোগ্য বৃষ্টির পূর্বাভাস থাকায় এখন সেচের প্রয়োজন নেই।',
    recent: 'সম্প্রতি সেচ দেওয়া হয়েছে, তাই এখন আবার সেচের প্রয়োজন নেই।',
    required: 'ফসলের পর্যায়, মাটির জলধারণ ক্ষমতা, আবহাওয়া ও সেচের ইতিহাস অনুযায়ী সেচ দেওয়ার পরামর্শ দেওয়া হচ্ছে।',
    harvested: 'কাটা হয়ে যাওয়া ফসলে সেচের প্রয়োজন নেই।',
  },
  hi: {
    morning: 'तेज़ धूप से पहले सुबह जल्दी',
    methods: { drip: 'ड्रिप सिंचाई', sprinkler: 'स्प्रिंकलर सिंचाई', flood: 'नियंत्रित बाढ़ सिंचाई', rainFed: 'पूरक सिंचाई', manual: 'जड़ क्षेत्र में हाथ से सिंचाई' },
    rain: 'पर्याप्त बारिश का पूर्वानुमान होने के कारण अभी सिंचाई आवश्यक नहीं है।',
    recent: 'हाल ही में सिंचाई की गई है, इसलिए अभी दोबारा सिंचाई आवश्यक नहीं है।',
    required: 'फसल अवस्था, मिट्टी की जलधारण क्षमता, मौसम और सिंचाई इतिहास के आधार पर सिंचाई की सलाह दी जाती है।',
    harvested: 'कटाई हो चुकी फसल को सिंचाई की आवश्यकता नहीं है।',
  },
};

export class RuleBasedIrrigationRecommendationProvider implements IrrigationRecommendationProvider {
  recommend(input: IrrigationRecommendationInput): IrrigationRecommendationOutput {
    const text = copy[input.language];
    const rain = input.rainForecastPercent ?? input.currentWeather?.rainProbabilityPercent ?? 0;
    const lastIrrigation = input.irrigationHistory[0] ?? null;
    const recentlyIrrigated = lastIrrigation != null
      && input.now.getTime() - lastIrrigation.occurredAt.getTime() < 2 * 86_400_000;
    const harvested = input.crop.growthStage === 'harvested';
    const rainExpected = rain >= 70;
    const required = !harvested && !rainExpected && !recentlyIrrigated;
    const millimeters = required ? this.waterDepth(input) : 0;
    const nextDate = new Date(input.now);
    nextDate.setUTCDate(nextDate.getUTCDate() + (rainExpected ? 2 : required ? this.interval(input.crop.growthStage) : harvested ? 14 : 2));
    const confidence = Math.min(0.96, 0.62
      + (input.currentWeather ? 0.1 : 0)
      + (input.rainForecastPercent != null ? 0.08 : 0)
      + (lastIrrigation ? 0.08 : 0)
      + 0.05);

    return {
      irrigationRequired: required,
      waterQuantity: {
        value: Math.round(millimeters * 4046.86),
        unit: 'liters',
        per: 'acre',
      },
      bestIrrigationTime: text.morning,
      irrigationMethod: text.methods[input.crop.irrigationMethod] ?? text.methods.manual,
      nextIrrigationDate: nextDate,
      confidence: Math.round(confidence * 100) / 100,
      reasoning: harvested ? text.harvested : rainExpected ? text.rain : recentlyIrrigated ? text.recent : text.required,
    };
  }

  private waterDepth(input: IrrigationRecommendationInput) {
    const stageDepth: Record<string, number> = {
      sowing: 12, germination: 12, seedling: 18, vegetative: 25,
      flowering: 30, fruiting: 28, maturity: 15,
    };
    const soilFactor = input.crop.soilType === 'sandy' ? 1.2
      : input.crop.soilType === 'clay' || input.crop.soilType === 'black' ? 0.8 : 1;
    const landFactor = input.landType === 'upland' ? 1.15
      : input.landType === 'lowland' ? 0.75 : 1;
    const weatherFactor = (input.currentWeather?.temperatureCelsius ?? 25) >= 35 ? 1.15
      : (input.currentWeather?.humidityPercent ?? 50) >= 85 ? 0.9 : 1;
    return (stageDepth[input.crop.growthStage] ?? 20) * soilFactor * landFactor * weatherFactor;
  }

  private interval(stage: string) {
    return stage === 'flowering' || stage === 'fruiting' ? 3
      : stage === 'seedling' || stage === 'vegetative' ? 4 : 6;
  }
}
