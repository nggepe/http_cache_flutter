import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:http_cache_flutter/src/http_cache_chiper.dart';
// ignore: implementation_imports
import 'package:hive/src/hive_impl.dart' as impl;

class HttpCacheStorage {
  HttpCacheStorage(this._box);

  final Box<dynamic> _box;

  dynamic read(String key) => _box.isOpen ? _box.get(key) : null;

  Future<void> write(String key, dynamic value) async {
    if (_box.isOpen) {
      return _box.put(key, value);
    }
  }

  Future<void> delete(String key) async {
    if (_box.isOpen) {
      return _box.delete(key);
    }
  }

  Future<void> clear() async {
    if (_box.isOpen) {
      _instance = null;
      await _box.clear();
    }
  }

  Future<void> invalidate(Pattern key) async {
    if (_box.isOpen) {
      final keys = _box.keys.toList();
      final invalidatedKeys = keys.where((element) {
        if (element is String) {
          return element.contains(key);
        }

        return false;
      }).toList();
      for (var i = 0; i < invalidatedKeys.length; i++) {
        await delete(invalidatedKeys[i]);
      }
    }
  }

  static final webStorageDirectory = Directory('');

  // Use HiveImpl directly to avoid conflicts with existing Hive.init
  // https://github.com/hivedb/hive/issues/336
  @visibleForTesting
  static HiveInterface hive = impl.HiveImpl();

  static Future<HttpCacheStorage> initialize({
    required Directory storageDirectory,
    HttpCacheChiper? chiper,
  }) async {
    if (_instance != null) return _instance!;

    Box<dynamic> box;

    if (storageDirectory == webStorageDirectory) {
      box = await hive.openBox<dynamic>('http_cache_flutter',
          encryptionCipher: chiper);
    } else {
      hive.init(storageDirectory.path);
      box = await hive.openBox<dynamic>('http_cache_flutter',
          encryptionCipher: chiper);
    }

    return HttpCacheStorage(box);
  }

  static HttpCacheStorage? _instance;
}
