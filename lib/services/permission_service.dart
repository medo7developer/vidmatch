import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  // التحقق من الأذونات
  static Future<bool> checkMediaPermissions() async {
    // التحقق أولاً من SharedPreferences للتحقق مما إذا كنا قد حفظنا الأذونات بالفعل
    final prefs = await SharedPreferences.getInstance();
    final savedPermissions = prefs.getBool('permissions_granted') ?? false;

    // إذا كانت الأذونات محفوظة، نتحقق مما إذا كانت لا تزال صالحة
    if (savedPermissions) {
      final cameraPermission = await Permission.camera.status;
      final microphonePermission = await Permission.microphone.status;

      // التحقق من صلاحية الأذونات
      return cameraPermission.isGranted && microphonePermission.isGranted;
    }

    return false;
  }

  // طلب الأذونات
  static Future<bool> requestMediaPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;
  }

  // حفظ حالة الأذونات
  static Future<void> savePermissionStatus(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_granted', granted);
  }

  // فتح إعدادات التطبيق
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}
