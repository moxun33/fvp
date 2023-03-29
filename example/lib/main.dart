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
      text: 'http://hdltc1.douyucdn.cn/live/747764rSurv4YkpQ.m3u8?uuid=');
  @override
  void initState() {
    super.initState();
    initFvp();
  }

  Future<void> initFvp() async {
    await updateTexture();

    //  play('https://hdltctwk.douyucdn2.cn/live/4549169rYnH7POVF.m3u8');
    //play('http://livehkkp.chinamcache.com/live/CCTV-xw.m3u8');
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
    // final vinfo = await _fvp.getOffScreenMediaInfo(url);

    await updateTexture();

    await _fvp.setMedia(url);
    _onEvents();
    final info = await _fvp.getMediaInfo();
    print(info.toString());
  }

  void _onEvents() {
    _fvp.onStateChanged((String state) {
      debugPrint("----state change $state");
    });
    _fvp.onMediaStatusChanged((String status) async {
      debugPrint("==== medias status change $status");
      if (status == '-2147483648') {
        setState(() {
          tip = 'playing failed';
        });
        //stop();
      }
    });
    _fvp.onEvent((Map<String, dynamic> data) async {
      debugPrint("****** on media event ${data}");
      final value = data['error'].toInt();
      switch (data['category']) {
        case 'reader.buffering':
          final percent = data['error'].toInt();
          if (percent < 100) {
            setState(() {
              tip = 'buffering $percent%';
            });
          } else {
            /*  final res = await _fvp.getMediaInfo(),
                videoCodec = res!["video"]["codec"] ?? {};
            debugPrint(
                'media info ${videoCodec["width"]} ${videoCodec["height"]}');
            _fvp.setVideoSurfaceSize(
                videoCodec["width"] as int, videoCodec["height"] as int); */
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
      // debugPrint('【render msg】 $msg');
    });
    _fvp.setLogHandler((msg) async {
      // debugPrint('【log msg】 $msg');

      //print('pos: $pos   buffered: $buff');
    });
  }

  void playOrPause() {
    _fvp.playOrPause();
    getMediaInfo();
  }

  Future<int> stop({bool? clear}) async {
    if (clear == true) _textureId = null;
    return _fvp.stop();
  }

  void getMediaInfo() async {
    final res = await _fvp.getMediaInfo();
    debugPrint('media info $res');
    // _fvp.snapshot();
  }

  @override
  void dispose() {
    super.dispose();
    stop();
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
