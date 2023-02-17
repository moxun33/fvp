import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fvp/fvp.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _fvpPlugin = Fvp();
  int? _textureId;
  String tip = '';
  final TextEditingController _urlController = TextEditingController();
  @override
  void initState() {
    super.initState();
    initFvp();
  }

  Future<void> initFvp() async {
    await updateTexture();
    play('https://hdltctwk.douyucdn2.cn/live/4549169rYnH7POVF.m3u8');
  }

  Future<int> updateTexture() async {
    if (_textureId != null) {
      await stop();
    }

    int ttId = await _fvpPlugin.createTexture();
    setState(() {
      _textureId = ttId;
    });
    debugPrint('textureId: $ttId');

    return ttId;
  }

  void play(url) async {
    setState(() {
      tip = 'opening';
    });
    updateTexture();
    await _fvpPlugin.setMedia(url);
    _fvpPlugin.onStateChanged((String state) {
      debugPrint("-------------------state change $state");
    });
    _fvpPlugin.onMediaStatusChanged((String status) {
      debugPrint("============medias status change $status");
      if (status == '-2147483648') {
        setState(() {
          tip = 'playing failed';
        });
      }
    });
    _fvpPlugin.onEvent((Map<String, dynamic> data) {
      debugPrint("******on media event ${data}");
      switch (data['category']) {
        case 'reader.buffering':
          final percent = data['error'].toInt();
          if (percent < 100) {
            setState(() {
              tip = 'buffering $percent%';
            });
          } else {
            setState(() {
              tip = '';
            });
          }

          break;
        default:
          break;
      }
    });
  }

  void playOrPause() {
    _fvpPlugin.playOrPause();
    getMediaInfo();
  }

  Future<int> stop() async {
    _textureId = null;
    return _fvpPlugin.stop();
  }

  void getMediaInfo() async {
    final res = await _fvpPlugin.getMediaInfo();
    debugPrint('media info $res');
    // _fvpPlugin.snapshot();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build textureId: $_textureId');
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: Text(
                  'Flutter Video Player based on libmdk. textureId: $_textureId'),
            ),
            body: Stack(children: [
              Container(
                  color: Colors.black,
                  child: _textureId != null
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Texture(
                              textureId: _textureId!,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        )
                      : const SizedBox()),
              Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: 500,
                    height: 100,
                    color: Colors.transparent,
                    child: Text(
                      tip,
                      style: const TextStyle(color: Colors.amber),
                    ),
                  )),
              Row(
                children: [
                  Container(
                    width: 500,
                    padding: const EdgeInsets.only(left: 120),
                    child: TextField(
                      decoration:
                          const InputDecoration(hintText: 'input video url'),
                      controller: _urlController,
                    ),
                  ),
                  TextButton(
                      child: const Text('play'),
                      onPressed: () => play(_urlController.text)),
                  ElevatedButton(
                      child: const Text('play/pause'),
                      onPressed: () => playOrPause()),
                  TextButton(
                      child: const Text('stop'),
                      onPressed: () {
                        stop();
                      }),
                ],
              ),
            ])));
  }
}
