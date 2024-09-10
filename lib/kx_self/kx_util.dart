import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';

class KxUtil {
  static final KxUtil of = KxUtil._();
  KxUtil._();

  static const String CONVERSATION_C2C_PREFIX = "c2c_";
  static const String CONVERSATION_GROUP_PREFIX = "group_";

  //  会话ID
  String getConversationID({required V2TimMessage message}) {
    if (message.groupID != null && message.groupID!.isNotEmpty) {
      return CONVERSATION_GROUP_PREFIX + message.groupID!;
    }
    if (message.userID == null) {
      return "";
    }
    return CONVERSATION_C2C_PREFIX + message.userID!;
  }
}
