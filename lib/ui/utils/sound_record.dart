import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as audio_players;
// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_plugin_record_plus/const/play_state.dart';
import 'package:flutter_plugin_record_plus/const/response.dart';
import 'package:flutter_plugin_record_plus/index.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tencent_cloud_chat_uikit/import_proxy/import_proxy.dart';

typedef PlayStateListener = void Function(PlayState playState);
typedef SoundInterruptListener = void Function();
typedef ResponseListener = void Function(RecordResponse recordResponse);

class SoundPlayer {
  final ImportProxy importProxy = ImportProxy();
  static final FlutterPluginRecord _recorder = FlutterPluginRecord();
  static SoundInterruptListener? _soundInterruptListener;
  static bool isInit = false;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static final _audioPlayers = audio_players.AudioPlayer();

  static initSoundPlayer() {
    if (!isInit) {
      _recorder.init();
      // AudioPlayer.global.setGlobalAudioContext(const AudioContext());
      isInit = true;
    }
  }

  static Future<void> playNew({required String url}) async {
    _audioPlayers.stop();
    if (_soundInterruptListener != null) {
      _soundInterruptListener!();
    }
    await _audioPlayers.play(audio_players.UrlSource(url));
  }

  static Future<void> play({required String url}) async {
    _audioPlayer.stop();
    if (_soundInterruptListener != null) {
      _soundInterruptListener!();
    }
    await _audioPlayer.setUrl(url);
    await _audioPlayer.play();
  }

  // 语音消息连续播放新增逻辑 begin
  static Future<void> playWith({required AudioSource source}) async {
    try {
      _audioPlayer.stop();
      if (_soundInterruptListener != null) {
        _soundInterruptListener!();
      }

      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('playWith e: $e');
    }
  }

  // 语音消息连续播放新增逻辑 begin
  static Future<void> playWithNew(
      {required audio_players.Source source}) async {
    try {
      _audioPlayers.stop();
      if (_soundInterruptListener != null) {
        _soundInterruptListener!();
      }

      await _audioPlayers.play(source);
    } catch (e) {
      debugPrint('playWith e: $e');
    }
  }

  ///  播放本地文件
  static Future<void> playWithAsset({required String asset}) async {
    _audioPlayer.stop();
    if (_soundInterruptListener != null) {
      _soundInterruptListener!();
    }
    await _audioPlayer.setAsset(asset, preload: false);
    await _audioPlayer.play();
  }

  ///  播放本地文件
  static Future<void> playWithAssetNew({required String asset}) async {
    _audioPlayers.stop();
    if (_soundInterruptListener != null) {
      _soundInterruptListener!();
    }
    await _audioPlayers.play(audio_players.AssetSource(asset));
  }

  // 语音消息连续播放新增逻辑 end

  static stop() {
    _audioPlayer.stop();
  }

  static dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
  }

  static StreamSubscription<PlayerState> playStateListener(
          {required void Function(PlayerState)? listener}) =>
      _audioPlayer.playerStateStream.listen(listener);

  static StreamSubscription<audio_players.PlayerState> playStateListenerNew(
          {required void Function(audio_players.PlayerState)? listener}) =>
      _audioPlayers.onPlayerStateChanged.listen(listener);

  static setSoundInterruptListener(SoundInterruptListener listener) {
    _soundInterruptListener = listener;
  }

  static removeSoundInterruptListener() {
    _soundInterruptListener = null;
  }

  static StreamSubscription<RecordResponse> responseListener(
          ResponseListener listener) =>
      _recorder.response.listen(listener);

  static StreamSubscription<RecordResponse> responseFromAmplitudeListener(
          ResponseListener listener) =>
      _recorder.responseFromAmplitude.listen(listener);

  static startRecord() {
    _recorder.start();
  }

  static stopRecord() {
    _recorder.stop();
  }
}
