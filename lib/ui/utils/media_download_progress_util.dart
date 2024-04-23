// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';

typedef DownloadListener = Function(
    String downloadKey, V2TimMessageDownloadProgress infoDetail);

class MediaDownloadProgressUtil {
  static final MediaDownloadProgressUtil of = MediaDownloadProgressUtil._();
  MediaDownloadProgressUtil._();

  final MessageService _messageService = serviceLocator<MessageService>();

  Map<String, DownloadListener> progressListeners = {};
  late V2TimAdvancedMsgListener advancedMsgListener;

  void init() {
    advancedMsgListener = V2TimAdvancedMsgListener(
      onMessageDownloadProgressCallback:
          (V2TimMessageDownloadProgress messageProgress) async {
        List<String> keys = progressListeners.keys
            .where((element) => element.contains(messageProgress.msgID))
            .toList();

        for (var key in keys) {
          progressListeners[key]?.call(key, messageProgress);
        }
      },
    );
    TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .addAdvancedMsgListener(listener: advancedMsgListener);
  }

  void dispose() {
    TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .removeAdvancedMsgListener(listener: advancedMsgListener);
  }

  //添加一个下载监听回调
  //  downloadKey 包含 msgId
  void addDownloadListener({
    required V2TimMessage message,
    required String downloadKey,
    required DownloadListener downloadListener,
  }) {
    //判断是否存在下载任务

    if (progressListeners.containsKey(downloadKey)) {
      debugPrint("MediaDownloadProgressUtil===>该下载任务已存在");
      return;
    }

    progressListeners[downloadKey] = downloadListener;
  }

  void removeListenerByKey({required String removeKey}) {
    /// 监听列表移除
    progressListeners.removeWhere((key, value) => key == removeKey);
  }

  // 下载桌面版视频资源视频
  Future<void> downloadVideo({
    required V2TimMessage message,
  }) async {
    if (TencentUtils.checkString(message.msgID) != null) {
      if (TencentUtils.checkString(message.videoElem!.videoUrl) == null) {
        final response =
            await _messageService.getMessageOnlineUrl(msgID: message.msgID!);
        if (response.data != null) {
          message.videoElem = response.data!.videoElem;
        }
      }
      if (!PlatformUtils().isWeb) {
        if (TencentUtils.checkString(message.videoElem!.localVideoUrl) ==
                null ||
            !File(message.videoElem!.localVideoUrl!).existsSync()) {
          _messageService.downloadMessage(
              msgID: message.msgID!,
              messageType: 5,
              imageType: 0,
              isSnapshot: false);
        }
      }
    }
  }
}
