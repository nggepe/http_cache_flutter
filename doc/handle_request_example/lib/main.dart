// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import "package:path_provider/path_provider.dart";
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "package:http_cache_flutter/http_cache_flutter.dart";
import 'package:http/http.dart' as http;

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
      home: const MyHomePage(title: 'Http cache demo'),
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
        refactorBody: (body) {
          var items = json.decode(body)["items"] as List?;
          return items?.map((e) {
                return GithubRepository.fromMap(e);
              }).toList() ??
              [];
        },
        handleRequest: handleRequest,
        staleTime: const Duration(hours: 23),
        cacheTime: const Duration(days: 1),
        builder: (_, data) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              bottom: PreferredSize(
                  preferredSize: Size(MediaQuery.of(context).size.width, 50),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            data.actions.changeUrl("${url}flutter/flutter");
                          },
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith(
                            (states) => Colors.green,
                          )),
                          child: const Text(
                            "flutter/flutter",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () {
                            data.actions.changeUrl("${url}flutter/engine");
                          },
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith(
                            (states) => Colors.green,
                          )),
                          child: const Text(
                            "flutter/engine",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )),
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
                            onPressed: data.actions.fetchWithLoading,
                            child: const Text('fetch')),
                      ],
                    ),
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: data.actions.fetchWithLoading,
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

Future<http.Response> handleRequest(
    String url, Map<String, String>? headers) async {
  http.Response response = await http.get(Uri.parse(url), headers: headers);
  return response;
}
