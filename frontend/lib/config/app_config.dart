class AppConfig {
  static const String baseUrl = "http://192.168.1.10:8000";

  static const String videoStreamUrl = "$baseUrl/video";
  static const String statusUrl = "$baseUrl/status";
  static const String feedManualUrl = "$baseUrl/feed/manual";
  static const String healthUrl = "$baseUrl/health";

  static const String mqttBroker = "broker.emqx.io";
  static const int mqttPort = 1883;
  static const String mqttClientId = "flutter_cat_feeder_app";
  static const String topicFeed = "cat/feeding";
  static const String topicStatus = "cat/status";
}
