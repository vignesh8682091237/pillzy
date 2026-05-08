// This file is a stub to prevent errors when compiling for mobile
// because dart:html is not available there.

class Notification {
  static String permission = 'denied';
  static Future<String> requestPermission() async => 'denied';

  Notification(String title, {String? body, String? icon});

  Stream<dynamic> get onClick => const Stream.empty();
}
