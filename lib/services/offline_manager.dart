import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineManager {
  static const String _offlineDbName = 'gramshiksha_offline.db';
  static const String _contentTable = 'offline_content';
  static const String _assignmentsTable = 'offline_assignments';
  static const String _announcementsTable = 'offline_announcements';

  late Database _database;

  // Singleton pattern
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  // Initialize the offline database
  Future<void> initialize() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _offlineDbName);

    _database = await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    // Create offline content table
    await db.execute('''
      CREATE TABLE $_contentTable(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        class_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        file_path TEXT,
        downloaded_at INTEGER NOT NULL
      )
    ''');

    // Create offline assignments table
    await db.execute('''
      CREATE TABLE $_assignmentsTable(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        class_id TEXT NOT NULL,
        due_date INTEGER,
        created_at INTEGER NOT NULL,
        downloaded_at INTEGER NOT NULL,
        attachment_path TEXT
      )
    ''');

    // Create offline announcements table
    await db.execute('''
      CREATE TABLE $_announcementsTable(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        class_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        downloaded_at INTEGER NOT NULL
      )
    ''');
  }

  // Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Download content for offline access
  Future<void> downloadContent({
    required String contentId,
    required String title,
    required String content,
    required String type,
    required String classId,
    String? filePath,
  }) async {
    await _database.insert(_contentTable, {
      'id': contentId,
      'title': title,
      'content': content,
      'type': type,
      'class_id': classId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'file_path': filePath,
      'downloaded_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _updateOfflineStatus(contentId, true);
  }

  // Download assignment for offline access
  Future<void> downloadAssignment({
    required String assignmentId,
    required String title,
    required String description,
    required String classId,
    DateTime? dueDate,
    String? attachmentPath,
  }) async {
    await _database.insert(_assignmentsTable, {
      'id': assignmentId,
      'title': title,
      'description': description,
      'class_id': classId,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'downloaded_at': DateTime.now().millisecondsSinceEpoch,
      'attachment_path': attachmentPath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Download announcement for offline access
  Future<void> downloadAnnouncement({
    required String announcementId,
    required String title,
    required String content,
    required String classId,
  }) async {
    await _database.insert(_announcementsTable, {
      'id': announcementId,
      'title': title,
      'content': content,
      'class_id': classId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'downloaded_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get offline content
  Future<List<OfflineContent>> getOfflineContent(String classId) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      _contentTable,
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'downloaded_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OfflineContent.fromMap(maps[i]);
    });
  }

  // Get offline assignments
  Future<List<OfflineAssignment>> getOfflineAssignments(String classId) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      _assignmentsTable,
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'downloaded_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OfflineAssignment.fromMap(maps[i]);
    });
  }

  // Get offline announcements
  Future<List<OfflineAnnouncement>> getOfflineAnnouncements(
    String classId,
  ) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      _announcementsTable,
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'downloaded_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OfflineAnnouncement.fromMap(maps[i]);
    });
  }

  // Check if content is available offline
  Future<bool> isContentAvailableOffline(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('offline_$contentId') ?? false;
  }

  // Update offline status
  Future<void> _updateOfflineStatus(String contentId, bool isOffline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_$contentId', isOffline);
  }

  // Remove offline content
  Future<void> removeOfflineContent(String contentId) async {
    await _database.delete(
      _contentTable,
      where: 'id = ?',
      whereArgs: [contentId],
    );
    await _updateOfflineStatus(contentId, false);
  }

  // Clear all offline data
  Future<void> clearAllOfflineData() async {
    await _database.delete(_contentTable);
    await _database.delete(_assignmentsTable);
    await _database.delete(_announcementsTable);

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('offline_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // Get offline storage size
  Future<String> getOfflineStorageSize() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _offlineDbName);
      final file = File(path);

      if (await file.exists()) {
        final sizeInBytes = await file.length();
        return _formatBytes(sizeInBytes);
      }
      return '0 MB';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// Models for offline data
class OfflineContent {
  final String id;
  final String title;
  final String content;
  final String type;
  final String classId;
  final DateTime createdAt;
  final DateTime downloadedAt;
  final String? filePath;

  OfflineContent({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.classId,
    required this.createdAt,
    required this.downloadedAt,
    this.filePath,
  });

  factory OfflineContent.fromMap(Map<String, dynamic> map) {
    return OfflineContent(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      type: map['type'],
      classId: map['class_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(map['downloaded_at']),
      filePath: map['file_path'],
    );
  }
}

class OfflineAssignment {
  final String id;
  final String title;
  final String description;
  final String classId;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime downloadedAt;
  final String? attachmentPath;

  OfflineAssignment({
    required this.id,
    required this.title,
    required this.description,
    required this.classId,
    this.dueDate,
    required this.createdAt,
    required this.downloadedAt,
    this.attachmentPath,
  });

  factory OfflineAssignment.fromMap(Map<String, dynamic> map) {
    return OfflineAssignment(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      classId: map['class_id'],
      dueDate:
          map['due_date'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['due_date'])
              : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(map['downloaded_at']),
      attachmentPath: map['attachment_path'],
    );
  }
}

class OfflineAnnouncement {
  final String id;
  final String title;
  final String content;
  final String classId;
  final DateTime createdAt;
  final DateTime downloadedAt;

  OfflineAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.classId,
    required this.createdAt,
    required this.downloadedAt,
  });

  factory OfflineAnnouncement.fromMap(Map<String, dynamic> map) {
    return OfflineAnnouncement(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      classId: map['class_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(map['downloaded_at']),
    );
  }
}
