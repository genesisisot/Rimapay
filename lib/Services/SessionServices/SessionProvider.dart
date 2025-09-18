import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


const String _sessionIdKey = 'session_id';


class SessionNotifier extends StateNotifier<String?> {
  SessionNotifier() : super(null) {
    _loadSessionId();
  }

  Future<void> _loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_sessionIdKey);
  }


  Future<void> saveSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
    state = sessionId;
  }


  Future<void> clearSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
    state = null;
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, String?>((ref) => SessionNotifier());
