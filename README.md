# HTTP Cache Flutter

<div style="text-align: center;">
  <img src="https://raw.githubusercontent.com/nggepe/http_cache_flutter/master/doc/bee-hive.png" style="max-width: 100%" />
</div>

[![codecov](https://codecov.io/gh/nggepe/http_cache_flutter/branch/master/graph/badge.svg?token=XJ6CGLNBHY)](https://codecov.io/gh/nggepe/http_cache_flutter)
[![pub package](https://img.shields.io/pub/v/http_cache_flutter.svg)](https://pub.dev/packages/http_cache_flutter)
[![code analyze](https://github.com/nggepe/http_cache_flutter/actions/workflows/code-analyze.yml/badge.svg)](https://github.com/nggepe/http_cache_flutter/actions/workflows/code-analyze.yml)

# Status

Currently, we are **in dev**. This status will change to stable when we reached the `HttpCache` Widget goal.

# Overview

The goal of this library is to make it easier for us to handle http requests and data caching by using interactive widgets.
**Current Target Goal**

## HttpCache Widget Goal

<table>
  <thead>
    <tr>
      <td>
        Feature
      </td>
      <td>
        Status
      </td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        Persistent Cache Storage
      </td>
      <td>
        ✅
      </td>
    </tr>
    <tr>
      <td>
        Handle Change URL
      </td>
      <td>
        ✅
      </td>
    </tr>
    <tr>
      <td>
        Handle stale data
      </td>
      <td>
        ✅
      </td>
    </tr>
    <tr>
      <td>
        Handle log
      </td>
      <td>
        ✅
      </td>
    </tr>
    <tr>
      <td>
        Handle timeout cache
      </td>
      <td>
      ⏳
      </td>
    </tr>
    <tr>
      <td>
        Handle Data Mutation
      </td>
      <td>
        ⏳
      </td>
    </tr>
    <tr>
      <td>
        Invalidate key
      </td>
      <td>
        ⏳
      </td>
    </tr>
  </tbody>
</table>

## HttpCachePaged Widget Goal

<table>
  <thead>
    <tr>
      <td>
        Feature
      </td>
      <td>
        Status
      </td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        Persistent Cache Storage
      </td>
      <td>
        ⏳
      </td>
    </tr>
    <tr>
      <td>
        Handle Change URL
      </td>
      <td>
        ⏳
      </td>
    </tr>
    <tr>
      <td>
        Handle stale data
      </td>
      <td>
        ⏳
      </td>
    </tr>
    <tr>
      <td>
        Handle log
      </td>
      <td>
        ⏳
      </td>
    </tr>
    <tr>
      <td>
        Handle timeout cache
      </td>
      <td>
        ⏳
      </td>
    </tr>
    <tr>
      <td>
        Handle Data Mutation
      </td>
      <td>
        ⏳
      </td>
    </tr>
    <tr>
      <td>
        Paged http cache
      </td>
      <td>
        ⏳
      </td>
    </tr>
    <tr>
      <td>
        Dev tool
      </td>
      <td>
        ⏳
      </td>
    </tr>
    <tr>
      <td>
        Paging
      </td>
      <td>
        ⏳
      </td>
    </tr>
  </tbody>
</table>

# Storage Initializing

Before implement this library, you should initialize the storage.
In your `main.dart` flutter file 👇🏻

```dart
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HttpCache.init(
      storageDirectory: kIsWeb
          ? HttpCacheStorage.webStorageDirectory
          : await getTemporaryDirectory());
  runApp(const MyApp());
}
```

# Usage Example

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HttpCache.init(
      storageDirectory: kIsWeb
          ? HttpCacheStorage.webStorageDirectory
          : await getTemporaryDirectory());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final url = "https://api.github.com/search/repositories?q=";
  @override
  Widget build(BuildContext context) {
    return HttpCache<List<GithubRepository>>(
        url: "${url}nggepe/http_cache_flutter",
        log: const HttpLog(showLog: true),
        refactorBody: (body, decodedBody) {
          var items = decodedBody['items'] as List?;
          return items?.map((e) {
                return GithubRepository.fromMap(e);
              }).toList() ??
              [];
        },
        builder: (_, data) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              bottom: PreferredSize(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            data.changeUrl("${url}flutter/flutter");
                          },
                          child: const Text(
                            "flutter/flutter",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith(
                            (states) => Colors.green,
                          )),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () {
                            data.changeUrl("${url}flutter/engine");
                          },
                          child: const Text(
                            "flutter/engine",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith(
                            (states) => Colors.green,
                          )),
                        ),
                      ],
                    ),
                  ),
                  preferredSize: Size(MediaQuery.of(context).size.width, 50)),
            ),
            body: Center(
              child: data.isLoading
                  ? const CircularProgressIndicator()
                  : ListView(
                      children: [
                        Column(
                          children: data.refactoredBody
                                  ?.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 8),
                                      child: Column(
                                        children: [
                                          Text(e.name),
                                          Text(e.fullName),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList() ??
                              [],
                        ),
                        TextButton(
                            onPressed: data.fetchWithLoading,
                            child: const Text('fetch')),
                      ],
                    ),
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: data.fetchWithLoading,
                child: const Icon(Icons.refresh)),
          );
        });
  }
}

class GithubRepository {
  final String nodeId;
  final String name;
  final String fullName;

  const GithubRepository(
      {required this.nodeId, required this.name, required this.fullName});

  factory GithubRepository.fromMap(Map<String, dynamic> map) {
    return GithubRepository(
      nodeId: map['node_id'],
      name: map['name'],
      fullName: map['full_name'],
    );
  }
}
```
