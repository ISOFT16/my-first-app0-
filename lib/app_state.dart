import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fox_ai.dart';

/// Состояние приложения Vigil AI: тема, настройки сервера и история чата.
class AppState extends ChangeNotifier {
  static const _kTheme = 'theme';
  static const _kAiBase = 'ai_base';
  static const _kAiKey = 'ai_key';
  static const _kAiModel = 'ai_model';
  static const _kAiChat = 'ai_chat';

  late SharedPreferences _prefs;

  ThemeMode themeMode = ThemeMode.system;
  String aiBase = '';
  String aiKey = '';
  String aiModel = '';
  List<AiMessage> aiChat = [];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values[(_prefs.getInt(_kTheme) ?? 0).clamp(0, 2).toInt()];
    aiBase = _prefs.getString(_kAiBase) ?? '';
    aiKey = _prefs.getString(_kAiKey) ?? '';
    aiModel = _prefs.getString(_kAiModel) ?? '';
    try {
      final raw = _prefs.getString(_kAiChat);
      if (raw != null) {
        aiChat = (jsonDecode(raw) as List)
            .map((e) => AiMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      aiChat = [];
    }
  }

  void touch() => notifyListeners();

  void saveAiChat() {
    final keep = aiChat.where((m) => !m.isError).toList();
    final tail = keep.length > 200 ? keep.sublist(keep.length - 200) : keep;
    _prefs.setString(_kAiChat, jsonEncode(tail.map((m) => m.toJson()).toList()));
  }

  void clearChat() {
    aiChat.clear();
    saveAiChat();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _prefs.setInt(_kTheme, mode.index);
    notifyListeners();
  }

  void setAiServer({required String base, required String key, required String model}) {
    aiBase = base.trim();
    aiKey = key.trim();
    aiModel = model.trim();
    _prefs.setString(_kAiBase, aiBase);
    _prefs.setString(_kAiKey, aiKey);
    _prefs.setString(_kAiModel, aiModel);
    notifyListeners();
  }
}
