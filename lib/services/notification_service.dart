import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Inicializa o serviço de notificações
  static Future<void> init() async {
    // Configuração para o Android (usa o ícone padrão gerado na área de trabalho)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuração para o iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Inicializa o plugin
    await _notificationsPlugin.initialize(initializationSettings);

    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // Método para disparar a notificação instantânea
  static Future<void> exibirNotificacao({
    required int id,
    required String titulo,
    required String corpo,
  }) async {
    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'sos_cidade_channel', // ID do canal
      'Chamados SOS Cidade', // Nome do canal visível nas definições do telemóvel
      channelDescription: 'Notificações de atualizações de chamados da cidade',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, titulo, corpo, notificationDetails);
  }
}
