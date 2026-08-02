import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';

abstract interface class AiResponseRepository {
  Future<AiResponseType> generateResponse({
    required String question,
    FarmLocation? location,
    CurrentWeather? weather,
    List<String> savedCrops = const [],
  });
}
