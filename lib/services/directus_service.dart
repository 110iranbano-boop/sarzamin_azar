import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/mission.dart';
import '../models/mission_run.dart';
import '../models/book.dart';
import '../models/book_comment.dart';
import '../models/bookshelf.dart';
import '../models/forum_topic.dart';
import '../models/forum_reply.dart';
import '../models/map_settings.dart';
import '../models/map_hotspot.dart';

class DirectusService {
  // دریافت لیست مأموریت‌ها
  static Future<List<Mission>> getMissions() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.missionsEndpoint}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => Mission.fromJson(json)).toList();
      }
      throw Exception('خطا در دریافت مأموریت‌ها: ${response.statusCode}');
    } catch (e) {
      throw Exception('مشکل در ارتباط با سرور: $e');
    }
  }

  // ثبت انجام مأموریت
  static Future<bool> submitMission(MissionRun run) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.missionRunsEndpoint}');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(run.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // چک کردن انجام شدن قبلی مأموریت
  static Future<bool> checkMissionRun(int userId, int missionId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/mission_runs?filter[user_id][_eq]=$userId&filter[mission_id][_eq]=$missionId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ثبت تاریخچه پاداش
  static Future<bool> logReward({
    required int userId,
    required int missionId,
    required int amount,
    required String reason,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/reward_ledger');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'mission_id': missionId,
          'amount': amount,
          'type': 'flame',
          'reason': reason,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // دریافت سابقه فعالیت‌های کاربر
  static Future<List<dynamic>> getUserHistory(int userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/mission_runs?filter[user_id][_eq]=$userId&sort=-submitted_at');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((item) => {
          'title': 'انجام مأموریت شماره ${item['mission_id']}',
          'date': item['submitted_at'] ?? '',
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // دریافت لیست کتاب‌ها
  static Future<List<Book>> getBooks() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/books');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => Book.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // دریافت نظرات یک کتاب
  static Future<List<BookComment>> getBookComments(int bookId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/book_comments?filter[book_id][_eq]=$bookId&sort=created_at');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => BookComment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ثبت نظر جدید
  static Future<bool> addBookComment(int bookId, int userId, String text, {int? parentId}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/book_comments');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'book_id': bookId,
          'user_id': userId,
          'comment_text': text,
          'parent_id': ?parentId,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // دریافت قفسه‌های کاربر
  static Future<List<Bookshelf>> getUserBookshelves(int userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/user_bookshelves?filter[user_id][_eq]=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => Bookshelf.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ساخت قفسه جدید
  static Future<bool> createBookshelf(int userId, String name, String topic, {bool isPrivate = false}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/user_bookshelves');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'topic': topic,
          'is_private': isPrivate,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // آپدیت قفسه
  static Future<bool> updateBookshelf(int shelfId, String name, String topic) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/user_bookshelves/$shelfId');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'topic': topic,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // حذف قفسه
  static Future<bool> deleteBookshelf(int shelfId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/user_bookshelves/$shelfId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // افزودن کتاب به قفسه
  static Future<bool> addBookToShelf(int shelfId, int bookId, int userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/user_books');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bookshelf_id': shelfId,
          'book_id': bookId,
          'user_id': userId,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // دریافت کتاب‌های داخل یک قفسه
  static Future<List<Book>> getBooksInShelf(int shelfId) async {
    final listUrl = Uri.parse('${ApiConfig.baseUrl}/items/user_books?filter[bookshelf_id][_eq]=$shelfId');
    try {
      final listResponse = await http.get(listUrl);
      if (listResponse.statusCode != 200) return [];
      final listData = jsonDecode(listResponse.body);
      final List items = listData['data'] ?? [];
      if (items.isEmpty) return [];
      List<int> bookIds = items.map((item) => item['book_id'] as int).toList();
      final booksUrl = Uri.parse('${ApiConfig.baseUrl}/items/books?filter[id][_in]=${bookIds.join(",")}');
      final booksResponse = await http.get(booksUrl);
      if (booksResponse.statusCode == 200) {
        final booksData = jsonDecode(booksResponse.body);
        final List booksList = booksData['data'] ?? [];
        return booksList.map((json) => Book.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // حذف کتاب از قفسه
  static Future<bool> removeBookFromShelf(int shelfId, int bookId, int userId) async {
    final findUrl = Uri.parse('${ApiConfig.baseUrl}/items/user_books?filter[bookshelf_id][_eq]=$shelfId&filter[book_id][_eq]=$bookId&filter[user_id][_eq]=$userId');
    try {
      final findResponse = await http.get(findUrl);
      if (findResponse.statusCode != 200) return false;
      final data = jsonDecode(findResponse.body);
      final List items = data['data'] ?? [];
      if (items.isEmpty) return false;
      final recordId = items.first['id'];
      final deleteUrl = Uri.parse('${ApiConfig.baseUrl}/items/user_books/$recordId');
      final deleteResponse = await http.delete(deleteUrl);
      return deleteResponse.statusCode == 204 || deleteResponse.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // دریافت لیست تاپیک‌ها
  static Future<List<ForumTopic>> getForumTopics() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/forum_topics?sort=-created_at');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => ForumTopic.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ساخت تاپیک جدید
  static Future<bool> createForumTopic(ForumTopic topic) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/forum_topics');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': topic.title,
          'content': topic.content,
          'creator_id': topic.creatorId,
          'min_rank': topic.minRank,
          'min_flames': topic.minFlames,
          'min_feathers': topic.minFeathers,
          'is_closed': topic.isClosed,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // دریافت نظرات یک تاپیک
  static Future<List<ForumReply>> getForumReplies(int topicId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/forum_replies?filter[topic_id][_eq]=$topicId&sort=created_at');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => ForumReply.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ثبت نظر جدید (با قابلیت پاسخ به نظر)
  static Future<bool> createForumReply(int topicId, int userId, String content, {int? parentId}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/forum_replies');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic_id': topicId,
          'user_id': userId,
          'content': content,
          'parent_id': parentId, // همیشه فرستاده می‌شود (حتی اگر null باشد)
        }),
      );
      print('REPLY RESPONSE: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('REPLY ERROR: $e');
      return false;
    }
  }

  // ویرایش تاپیک
  static Future<bool> updateForumTopic(int topicId, String title, String content) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/forum_topics/$topicId');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'content': content,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // حذف تاپیک
  static Future<bool> deleteForumTopic(int topicId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/forum_topics/$topicId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
    // 💡 حذف نظر (پاسخ)
  static Future<bool> deleteForumReply(int replyId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/forum_replies/$replyId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
    // 💡 دریافت تنظیمات نقشه
  static Future<MapSettings?> getMapSettings() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/map_settings?filter[is_active][_eq]=true');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        if (items.isNotEmpty) return MapSettings.fromJson(items.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 💡 دریافت نقاط قابل کلیک روی نقشه
  static Future<List<MapHotspot>> getMapHotspots() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items/map_hotspots?filter[is_active][_eq]=true');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => MapHotspot.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}