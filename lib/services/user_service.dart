import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class UserService {
  // ذخیره آیدی کاربر در حافظه
  static Future<void> saveUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', id);
  }

  // خواندن آیدی کاربر از حافظه
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  // خروج از حساب (پاک کردن آیدی)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  // پیدا کردن کاربر با شماره موبایل
  static Future<Map<String, dynamic>?> findUser(String mobile) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}?filter[mobile][_eq]=$mobile');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List users = data['data'] ?? [];
        if (users.isNotEmpty) {
          return users.first; // کاربر پیدا شد
        }
      }
      return null; // کاربر پیدا نشد
    } catch (e) {
      return null;
    }
  }

  // ساخت کاربر جدید
  static Future<Map<String, dynamic>?> createUser(String mobile) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'name': 'کاربر جدید',
          'username': 'user_${mobile.substring(mobile.length - 4)}', // مثلا user_6789
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 💡 اضافه کردن شعله به کاربر
  static Future<bool> addFlamesToUser(int userId, int amount) async {
    try {
      final getUrl = Uri.parse('${ApiConfig.baseUrl}/items/users/$userId?fields=flames,total_flames_earned');
      final getResponse = await http.get(getUrl);
      if (getResponse.statusCode != 200) return false;
      
      final userData = jsonDecode(getResponse.body)['data'];
      int currentFlames = userData['flames'] ?? 0;
      int currentTotal = userData['total_flames_earned'] ?? 0;

      final patchUrl = Uri.parse('${ApiConfig.baseUrl}/items/users/$userId');
      final patchResponse = await http.patch(
        patchUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'flames': currentFlames + amount,
          'total_flames_earned': currentTotal + amount,
        }),
      );

      return patchResponse.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 💡 دریافت اطلاعات کامل کاربر (کد جدید)
  static Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/users/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 💡 تبدیل ۵۰ شعله به ۱ پر ققنوس (کد جدید)
  static Future<bool> convertFlamesToFeather(int userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      int currentFlames = profile['flames'] ?? 0;
      int currentFeathers = profile['phoenix_feathers'] ?? 0;

      if (currentFlames < 50) return false;

      final patchUrl = Uri.parse('${ApiConfig.baseUrl}/items/users/$userId');
      final patchResponse = await http.patch(
        patchUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'flames': currentFlames - 50,
          'phoenix_feathers': currentFeathers + 1,
        }),
      );

      if (patchResponse.statusCode == 200) {
        // ثبت در تاریخچه تبدیل
        final logUrl = Uri.parse('${ApiConfig.baseUrl}/items/conversion_logs');
        await http.post(
          logUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'flames_spent': 50,
            'feathers_gained': 1,
          }),
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
    // 💡 آپدیت اطلاعات پروفایل کاربر
  static Future<bool> updateUserProfile(int userId, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/users/$userId');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}