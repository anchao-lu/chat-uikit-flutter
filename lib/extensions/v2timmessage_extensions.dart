import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';

extension MsgExpired on V2TimMessage? {
  bool get isExpired {
    if (this == null) return false;
    final msgTimestamp = this?.timestamp;
    if (msgTimestamp != null) {
      final msgTime = DateTime.fromMillisecondsSinceEpoch(msgTimestamp * 1000);
      final now = DateTime.now();
      final diffDuration = now.difference(msgTime);
      final diffDays = diffDuration.inDays;
      // 超过30天的消息，不管啥情况都不开启下载
      if (diffDays >= 30) {
        return true;
      }
    }
    return false;
  }
}
