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
  final _fvp = Fvp();
  final _offFvp = Fvp();
  int? _textureId;
  String tip = '';
  final TextEditingController _urlController = TextEditingController(
      text: 'https://hdltctwk.douyucdn2.cn/live/5033502r1DnQtDRG.xs');
  @override
  void initState() {
    super.initState();
    initFvp();
  }

  Future<void> initFvp() async {
    await updateTexture();
    //  play('https://hdltctwk.douyucdn2.cn/live/4549169rYnH7POVF.m3u8');
    //play('http://livehkkp.chinamcache.com/live/CCTV-xw_4000.m3u8');
    //getOffScreenInfo();
  }

  Future<int> updateTexture() async {
    if (_textureId != null) {
      await stop();
    }

    int ttId = await _fvp.createTexture();
    setState(() {
      _textureId = ttId;
    });
    debugPrint('textureId: $ttId');

    return ttId;
  }

//离线媒体信息
  void getOffScreenInfo() async {
    final v = await _offFvp.getOffScreenMediaInfo(_urlController.text);
  }

  void play(url) async {
    setState(() {
      tip = 'opening';
    });
    updateTexture();
    await _fvp.setHeaders({
      'Referer':
          'https://web.hkkp.cnscn.com/sltv_html/165/165kds/2439579.shtml',
    });
    final headers = await _fvp.getProperty('headers');

    await _fvp.setMedia(url);
    _onEvents();
    final info = await _fvp.getMediaInfo();
    print(info.toString());
  }

  void _onEvents() {
    _fvp.onStateChanged((String state) {
      debugPrint("------------------- state change $state");
    });
    _fvp.onMediaStatusChanged((String status) {
      debugPrint("============ medias status change $status");
      if (status == '-2147483648') {
        setState(() {
          tip = 'playing failed';
        });
      }
    });
    _fvp.onEvent((Map<String, dynamic> data) {
      debugPrint("----- ****** on media event ${data}");
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
    _fvp.onRenderCallback((String msg) {
      print('rendermsg $msg');
    });
  }

  void playOrPause() {
    _fvp.playOrPause();
    getMediaInfo();
  }

  Future<int> stop() async {
    _textureId = null;
    return _fvp.stop();
  }

  void getMediaInfo() async {
    final res = await _fvp.getMediaInfo();
    debugPrint('media info $res');
    // _fvp.snapshot();
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
                    color: Colors.white,
                    width: 500,
                    padding: const EdgeInsets.only(left: 10),
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
