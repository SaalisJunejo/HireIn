import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/helpers.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._();

  LocalDatabase._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // In-memory cache: collection -> map of (id -> doc)
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};

  // Stream controllers for reactivity
  final Map<String, StreamController<List<Map<String, dynamic>>>> _controllers = {};

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    // Load all known collections into memory
    final collections = ['users', 'providers', 'bookings', 'disputes', 'announcements', 'admin_logs'];
    for (final col in collections) {
      _data[col] = {};
      final String? jsonStr = _prefs.getString('db_$col');
      if (jsonStr != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(jsonStr);
          decoded.forEach((key, value) {
            _data[col]![key] = Map<String, dynamic>.from(value);
          });
        } catch (e) {
          Helpers.log('LocalDatabase', 'Error parsing collection $col: $e', isError: true);
        }
      }
    }
    
    _initialized = true;
    Helpers.log('LocalDatabase', 'Local JSON database initialized via SharedPreferences');
  }

  Future<void> _flush(String collection) async {
    final str = jsonEncode(_data[collection]);
    await _prefs.setString('db_$collection', str);
    _broadcast(collection);
  }

  void _broadcast(String collection) {
    if (_controllers.containsKey(collection) && !_controllers[collection]!.isClosed) {
      _controllers[collection]!.add(getAll(collection));
    }
  }

  Future<void> put(String collection, String id, Map<String, dynamic> data) async {
    if (!_initialized) await init();
    if (!_data.containsKey(collection)) _data[collection] = {};
    
    _data[collection]![id] = data;
    await _flush(collection);
  }

  Future<void> delete(String collection, String id) async {
    if (!_initialized) await init();
    if (_data.containsKey(collection) && _data[collection]!.containsKey(id)) {
      _data[collection]!.remove(id);
      await _flush(collection);
    }
  }

  Map<String, dynamic>? get(String collection, String id) {
    if (!_data.containsKey(collection)) return null;
    return _data[collection]![id];
  }

  List<Map<String, dynamic>> getAll(String collection) {
    if (!_data.containsKey(collection)) return [];
    return _data[collection]!.values.toList();
  }

  List<Map<String, dynamic>> query(String collection, bool Function(Map<String, dynamic>) where) {
    if (!_data.containsKey(collection)) return [];
    return _data[collection]!.values.where(where).toList();
  }

  StreamController<List<Map<String, dynamic>>> _getOrCreateController(String collection) {
    if (!_controllers.containsKey(collection)) {
      _controllers[collection] = StreamController<List<Map<String, dynamic>>>.broadcast();
    }
    return _controllers[collection]!;
  }

  Stream<List<Map<String, dynamic>>> watch(String collection) {
    late StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? subscription;

    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () {
        // Emit current value immediately
        controller.add(getAll(collection));
        
        // Listen to the main updates
        final mainStream = _getOrCreateController(collection).stream;
        subscription = mainStream.listen((event) {
          if (!controller.isClosed) {
            controller.add(event);
          }
        });
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
