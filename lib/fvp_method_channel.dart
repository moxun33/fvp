import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fvp/fvp_utils.dart';

import 'fvp_platform_interface.dart';

/// An implementation of [FvpPlatform] that uses method channels.
class MethodChannelFvp extends FvpPlatform {
  MethodChannelFvp() {
    methodChannel.setMethodCallHandler(_methodCallHandler);
  }

  static final MethodChannelFvp _instance = MethodChannelFvp();

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('fvp');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<int> createTexture() async {
    final tex = await methodChannel.invokeMethod('CreateRT');
    return tex;
  }

  @override
  Future<int> setMedia(String? url,
      {String headers = '', String ua = ''}) async {
    if (!(url != null && url.isNotEmpty)) {
      return 0;
      // throw ArgumentError('url 不能为空');
    }
    return (await methodChannel.invokeMethod(
        'setMedia', {'url': url, 'headers': headers, 'ua': ua})) as int;
  }

  @override
  Future<Map<String, dynamic>?> getOffScreenMediaInfo(String? url,
      {String headers = '', String ua = ''}) async {
    if (!(url != null && url.isNotEmpty)) {
      return null;
      // throw ArgumentError('url 不能为空');
    }
    try {
      return Map<String, dynamic>.from(await methodChannel.invokeMethod(
          'getOffScreenMediaInfo', {'url': url, 'headers': headers, 'ua': ua}));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> playOrPause() async {
    return (await methodChannel.invokeMethod('playOrPause')) as int;
  }

  @override
  Future<Map<String, dynamic>?> getMediaInfo() async {
    try {
      return Map<String, dynamic>.from(
          await methodChannel.invokeMethod('getMediaInfo'));
    } catch (e) {
      return null;
    }
  }

//v: 0 , 0.5,0.6, 1.0
  @override
  Future<int> setVolume(double v) async {
    return (await methodChannel.invokeMethod(
        'setVolume', {'volume': v > 0 && v <= 1 ? v : 1.0}) as int);
  }

  @override
  Future<int> setMute(bool? v) async {
    return (await methodChannel.invokeMethod('setMute', {'mute': v ?? true})
        as int);
  }

  //v： ms
  @override
  Future<int> setTimeout(int? v) async {
    return (await methodChannel.invokeMethod('setTimeout', {'time': v ?? 10000})
        as int);
  }

  @override
  Future<int> getState() async {
    return (await methodChannel.invokeMethod('getState') as int);
  }

  @override
  Future<int> getStatus() async {
    return (await methodChannel.invokeMethod('getStatus') as int);
  }

  @override
  Future<String?> snapshot() async {
    try {
      return methodChannel.invokeMethod('snapshot');
    } catch (e) {
      return null;
    }
  }

  @override
  Future<double> volume() async {
    return (await methodChannel.invokeMethod('volumme')) as double;
  }

  @override
  Future<int> position() async {
    return (await methodChannel.invokeMethod('position')) as int;
  }

  @override
  Future<int> buffered() async {
    return (await methodChannel.invokeMethod('buffered')) as int;
  }

  @override
  Future<int> stop() async {
    return (await methodChannel.invokeMethod('stop')) as int;
  }

  @override
  Future<int> setLogLevel(String? l) async {
    return (await methodChannel.invokeMethod('setLogLevel', {'level': l}))
        as int;
  }

  @override
  Future<int> setVideoSurfaceSize(int width, int height) async {
    return (await methodChannel.invokeMethod(
        'setVideoSurfaceSize', {'width': width, 'height': height})) as int;
  }

  @override
  Future<int> setUserAgent(String? ua) async {
    return (await methodChannel.invokeMethod('setUserAgent', {
      'ua': ua ??
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36 FVP ZTE"
    }) as int);
  }

  @override
  Future<int> setHeaders(Map<String, String>? headers) async {
    String head = "";
    headers?.forEach((key, value) {
      head = '$head$key: $value\r\n\t';
    });
    if (head.isEmpty) return 0;
    return (await methodChannel.invokeMethod('setHeaders', {'headers': head})
        as int);
  }

  @override
  Future<String> getProperty(String key) async {
    return (await methodChannel.invokeMethod('getProperty', {'key': key})
        as String);
  }

  @override
  Future<int> setProperty(String key, String value) async {
    return (await methodChannel
        .invokeMethod('setProperty', {'key': key, 'value': value}) as int);
  }

  @override
  Future<int> setDecoder(String decoder, int type) async {
    return (await methodChannel
        .invokeMethod('setDecoder', {'decoder': decoder, 'type': type}) as int);
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    final args = call.arguments;
    /*   if (kDebugMode) {
      print("cb from native method ${call.method}");
      print("cb from native args ${args.toString()}");
    } */

    switch (call.method) {
      case "onMediaStatusChanged":
        mediaStatusChangeCb(args.toString());

        break;
      case "onStateChanged":
        stateChangeCb(args.toString());

        break;
      case "onEvent":
        eventCb(Map<String, dynamic>.from(args));
        break;
      case "onRenderCallback":
        renderCb(args.toString());

        break;
      case "onLog":
        logHandler(args.toString());

        break;
      default:
        break;
    }
  }

  Function stateChangeCb = () {};
  Function mediaStatusChangeCb = () {};
  Function eventCb = () {};
  Function renderCb = () {};
  Function logHandler = () {};
  @override
  void onStateChanged(void Function(String state)? cb) {
    if (cb != null) {
      stateChangeCb = cb;
    }
  }

  @override
  void onMediaStatusChanged(void Function(String status)? cb) {
    if (cb != null) {
      mediaStatusChangeCb = cb;
    }
  }

  @override
  void onEvent(void Function(Map<String, dynamic> data)? cb) {
    if (cb != null) {
      eventCb = cb;
    }
  }

  @override
  void onRenderCallback(void Function(String msg)? cb) {
    if (cb != null) {
      renderCb = cb;
    }
  }

  @override
  Future<void> setLogHandler(void Function(String msg)? cb,
      {String? level, String? ffmpegLevel}) async {
    if (cb != null) {
      logHandler = cb;
    }

    (await methodChannel.invokeMethod(
        'setLogHandler', {'level': level, 'ffmpegLevel': ffmpegLevel}));
  }
}
