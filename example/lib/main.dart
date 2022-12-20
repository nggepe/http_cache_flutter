import 'dart:convert';

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
