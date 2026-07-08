import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/app_config.dart';

class MqttService {
  MqttServerClient? _client;

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  final StreamController<String> _feedController =
      StreamController<String>.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get feedStream => _feedController.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect() async {
    final clientId =
        "${AppConfig.mqttClientId}_${DateTime.now().millisecondsSinceEpoch}";

    _client = MqttServerClient.withPort(
      AppConfig.mqttBroker,
      clientId,
      AppConfig.mqttPort,
    );

    _client!.keepAlivePeriod = 30;
    _client!.logging(on: false);
    _client!.autoReconnect = true;
    _client!.onConnected = () => print("🟢 MQTT (Flutter) Connected");
    _client!.onDisconnected = () => print("🔴 MQTT (Flutter) Disconnected");
    _client!.onSubscribed = (topic) => print("Subscribed: $topic");

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      print("⚠️ MQTT connect error: $e");
      _client!.disconnect();
      return;
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      _client!.subscribe(AppConfig.topicStatus, MqttQos.atLeastOnce);
      _client!.subscribe(AppConfig.topicFeed, MqttQos.atLeastOnce);

      _client!.updates!.listen((events) {
        final recMess = events[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        final topic = events[0].topic;

        if (topic == AppConfig.topicStatus) {
          _statusController.add(payload);
        } else if (topic == AppConfig.topicFeed) {
          _feedController.add(payload);
        }
      });
    }
  }

  void disconnect() {
    _client?.disconnect();
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _feedController.close();
  }
}
