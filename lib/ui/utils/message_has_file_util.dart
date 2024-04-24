import 'dart:io';

import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';

class MessageHasFileUtil {
  static final MessageHasFileUtil of = MessageHasFileUtil._();
  MessageHasFileUtil._();

  (bool fileBeenDownloaded, String filePath) hasFile(
    V2TimMessage? message,
    TUIChatGlobalModel globalModel,
  ) {
    if (message == null) return (false, '');
    if (PlatformUtils().isMobile ||
        (message.fileElem == null &&
            message.imageElem == null &&
            message.videoElem == null)) {
      return (false, '');
    }
    if (PlatformUtils().isWeb) {
      return (false, '');
    }

    String savePath = '';

    if (PlatformUtils().isDesktop) {
      savePath = TencentUtils.checkString(
              globalModel.getFileMessageLocation(message.msgID)) ??
          '';
      if (savePath.isEmpty) {
        if (message.fileElem != null) {
          savePath = TencentUtils.checkString(message.fileElem!.localUrl) ??
              message.fileElem?.path ??
              "";
        } else if (message.imageElem != null) {
          final localUrl = (message.imageElem!.imageList ?? [])
                  .firstWhere(
                      (element) => element?.localUrl?.isNotEmpty == true)
                  ?.localUrl ??
              '';
          savePath = TencentUtils.checkString(localUrl) ?? "";
        } else if (message.videoElem != null) {
          savePath =
              TencentUtils.checkString(message.videoElem!.localVideoUrl!) ?? "";
        }
      }
    }

    File f = File(savePath);
    bool fileBeenDownloaded = false;
    if (f.existsSync() && message.msgID != null) {
      fileBeenDownloaded = true;
    }
    return (fileBeenDownloaded, savePath);
  }
}
