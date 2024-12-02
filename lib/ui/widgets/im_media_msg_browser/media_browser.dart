import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';

import 'browser_page_routes.dart';
import 'im_media_msg_browser.dart';

class MediaBrowser {
  MediaBrowser._();

  static void showIMMediaMsg(
    BuildContext context, {
    required V2TimMessage curMsg,
    required String? userID,
    required String? groupID,
    required String? isFrom,
    ValueChanged<String>? onDownloadVideo,
    ValueChanged<V2TimMessage>? onImgLongPress,
    ValueChanged<V2TimMessage>? onImgViewPress,
    ValueChanged<V2TimMessage>? onImgMorePress,
    ValueChanged<V2TimMessage>? onDownloadImage,
  }) {
    if (PlatformUtils().isDesktop) {
      showDialog(
          context: context,
          builder: (context) {
            const Size defaultWideSize = Size(414, 730);
            return UnconstrainedBox(
              child: SizedBox(
                height: defaultWideSize.height,
                width: defaultWideSize.width*2 ,
                child: IMMediaMsgBrowser(
                  curMsg: curMsg,
                  userID: userID,
                  groupID: groupID,
                  isFrom: isFrom,
                  onDownloadVideo: onDownloadVideo,
                  onImgLongPress: onImgLongPress,
                  onDownloadImage: onDownloadImage,
                  onImgViewPress: onImgViewPress,
                  onImgMorePress: onImgMorePress,

                ),
              ),
            );
          });
    } else {
      Navigator.push(
        context,
        BrowserTransparentPageRoute(
          pageBuilder: (_, __, ___) => IMMediaMsgBrowser(
            curMsg: curMsg,
            userID: userID,
            groupID: groupID,
            isFrom: isFrom,
            onDownloadVideo: onDownloadVideo,
            onImgLongPress: onImgLongPress,
            onDownloadImage: onDownloadImage,
            onImgMorePress: onImgMorePress,
            onImgViewPress: onImgViewPress,
          ),
        ),
      );
    }
  }
}
