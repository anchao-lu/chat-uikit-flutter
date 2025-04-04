import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
// ignore: unnecessary_import
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/chat_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_model_tools.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/group/group_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/constants/history_message_constant.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/sound_record.dart';
import 'package:uuid/uuid.dart';

enum LoadDirection { previous, latest }

class TUIChatSeparateViewModel extends ChangeNotifier {
  //////////////// 新增语音消息播放错误回调 ////////////////
  final CoreServicesImpl _coreServices = serviceLocator<CoreServicesImpl>();
  //////////////// 新增语音消息播放错误回调 ////////////////

  final FriendshipServices _friendshipServices =
      serviceLocator<FriendshipServices>();
  final MessageService _messageService = serviceLocator<MessageService>();
  final GroupServices _groupServices = serviceLocator<GroupServices>();
  final TUIChatGlobalModel globalModel = serviceLocator<TUIChatGlobalModel>();
  final TUIChatModelTools tools = serviceLocator<TUIChatModelTools>();
  final TUISelfInfoViewModel selfModel = serviceLocator<TUISelfInfoViewModel>();
  final _uuid = const Uuid();

  ChatLifeCycle? lifeCycle;
  int _totalUnreadCount = 0;
  bool _isMultiSelect = false;
  bool _isInit = false;
  String conversationID = "";
  ConvType? conversationType;
  bool haveMoreData = false;
  bool haveMoreLatestData = false;
  String _currentPlayedMsgId = "";
  GroupReceiptAllowType? _groupType;
  List<V2TimMessage> _multiSelectedMessageList = [];
  V2TimMessage? _repliedMessage;
  String _jumpMsgID = "";
  bool _isGroupExist = true;
  bool _isNotAMember = false;
  bool showC2cMessageEditStatus = true;
  TIMUIKitChatConfig chatConfig = const TIMUIKitChatConfig();
  ValueChanged<String>? setInputField;
  String? Function(V2TimMessage message)? abstractMessageBuilder;
  Function(String userID, TapDownDetails tapDetails)? onTapAvatar;
  V2TimGroupMemberFullInfo? _currentChatUserInfo;
  V2TimGroupInfo? _groupInfo;
  String groupMemberListSeq = "0";
  List<V2TimGroupMemberFullInfo?>? groupMemberList = [];
  V2TimGroupMemberFullInfo? selfMemberInfo;
  double atPositionX = 0.0;
  double atPositionY = 0.0;
  int _activeAtIndex = -1;
  List<V2TimGroupMemberFullInfo?> _showAtMemberList = [];
  Map<String, String> _groupUserShowName = {};
  String? _groupID;

  Map<String, String> get groupUserShowName => _groupUserShowName;
  final List<String> _sendingMessageIDList = [];

  set groupUserShowName(Map<String, String> value) {
    _groupUserShowName = value;
    _notify();
  }

  int get activeAtIndex => _activeAtIndex;

  set activeAtIndex(int value) {
    _activeAtIndex = value;
    _notify();
  }

  //////////// 新增属性：用于桌面端 @ 时的关键字搜索 ////////////
  String _desktopAtKeywords = '';
  String get desktopAtKeywords => _desktopAtKeywords;
  set desktopAtKeywords(String keywords) {
    _desktopAtKeywords = keywords;
    notifyListeners();
  }
  //////////// 新增属性：用于桌面端 @ 时的关键字搜索 ////////////

  List<V2TimGroupMemberFullInfo?> get showAtMemberList => _showAtMemberList;

  set showAtMemberList(List<V2TimGroupMemberFullInfo?> value) {
    _showAtMemberList = value;
    _notify();
  }

  V2TimGroupInfo? get groupInfo => _groupInfo;

  set groupInfo(V2TimGroupInfo? value) {
    _groupInfo = value;
    _notify();
  }

  int get totalUnreadCount => _totalUnreadCount;

  set totalUnreadCount(int value) {
    _totalUnreadCount = value;
    _notify();
  }

  bool get isMultiSelect => _isMultiSelect;

  set isMultiSelect(bool value) {
    _isMultiSelect = value;
    _notify();
  }

  String get currentPlayedMsgId => _currentPlayedMsgId;

  set currentPlayedMsgId(String value) {
    _currentPlayedMsgId = value;
    _notify();
  }

  GroupReceiptAllowType? get groupType => _groupType;

  set groupType(GroupReceiptAllowType? value) {
    _groupType = value;
    _notify();
  }

  List<V2TimMessage> get multiSelectedMessageList => _multiSelectedMessageList;

  set multiSelectedMessageList(List<V2TimMessage> value) {
    _multiSelectedMessageList = value;
    _notify();
  }

  V2TimMessage? get repliedMessage => _repliedMessage;

  set repliedMessage(V2TimMessage? value) {
    _repliedMessage = value;
    _notify();
  }

  String get jumpMsgID => _jumpMsgID;

  set jumpMsgID(String value) {
    _jumpMsgID = value;
    _notify();
  }

  bool get isGroupExist => _isGroupExist;

  set isGroupExist(bool value) {
    _isGroupExist = value;
    _notify();
  }

  bool get isNotAMember => _isNotAMember;

  set isNotAMember(bool value) {
    _isNotAMember = value;
    _notify();
  }

  V2TimGroupMemberFullInfo? get currentChatUserInfo => _currentChatUserInfo;

  set currentChatUserInfo(V2TimGroupMemberFullInfo? value) {
    _currentChatUserInfo = value;
    _notify();
  }

  setLoadingMessageMap(String conversationID, V2TimMessage messageInfo) {
    if (PlatformUtils().isWeb) {
      if (globalModel.loadingMessage[conversationID] != null &&
          globalModel.loadingMessage[conversationID]!.isNotEmpty) {
        globalModel.loadingMessage[conversationID]!.add(messageInfo);
      } else {
        globalModel.loadingMessage[conversationID] = <V2TimMessage>[
          messageInfo
        ];
      }
    }
  }

  void getUserShowName(List<String> userIDs) async {
    final List<String> filteredList = userIDs
        .where((element) => !_groupUserShowName.containsKey(element))
        .toList();
    for (final element in filteredList) {
      _groupUserShowName[element] = element;
    }

    final String groupID = TencentUtils.checkString(_groupID) ?? conversationID;

    if (filteredList.isNotEmpty) {
      final res = await TencentImSDKPlugin.manager
          ?.getGroupManager()
          .getGroupMembersInfo(groupID: groupID, memberList: filteredList);
      if (res?.code == 0 && res?.data != null) {
        final data = res!.data;
        for (final userInfo in data!) {
          final showName = TencentUtils.checkString(userInfo.nameCard) ??
              TencentUtils.checkString(userInfo.nickName) ??
              TencentUtils.checkString(userInfo.userID);
          if (TencentUtils.checkString(showName) != null) {
            _groupUserShowName[userInfo.userID] = showName ?? userInfo.userID;
          }
        }
        if (data.isNotEmpty) {
          _notify();
        }
      }
    }
  }

  void initForEachConversation(ConvType convType, String convID,
      ValueChanged<String>? onChangeInputField,
      {String? groupID,
      List<V2TimGroupMemberFullInfo?>? preGroupMemberList}) async {
    if (_isInit) {
      return;
    }
    setInputField = onChangeInputField;
    conversationType = convType;
    conversationID = convID;

    _groupType = null;
    isGroupExist = true;
    _groupInfo = null;
    groupMemberList = null;
    selfMemberInfo = null;

    globalModel.setCurrentConversation(
        CurrentConversation(conversationID, conversationType ?? ConvType.c2c));
    globalModel.lifeCycle = lifeCycle;
    globalModel.setMessageListPosition(
        conversationID, HistoryMessagePosition.bottom);
    globalModel.setChatConfig(chatConfig);
    globalModel.clearRecivedNewMessageCount();

    if (conversationType == ConvType.group) {
      _groupID = groupID;
      _notify();
      Future.delayed(const Duration(milliseconds: 10), () async {
        globalModel.refreshGroupApplicationList();
        loadGroupInfo(groupID ?? convID);
        if (preGroupMemberList != null) {
          groupMemberList = preGroupMemberList;
          selfMemberInfo = preGroupMemberList.firstWhereOrNull(
              (e) => e?.userID == selfModel.loginInfo?.userID);
        } else {
          await loadSelfMemberInfo(groupID: groupID ?? convID);
          loadGroupMemberList(groupID: groupID ?? convID);
        }
        if (selfMemberInfo == null) {
          await loadSelfMemberInfo(groupID: groupID ?? convID);
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 10), () async {
        final List<V2TimFriendInfoResult>? friendRes =
            await _friendshipServices.getFriendsInfo(userIDList: [convID]);
        if (friendRes != null && friendRes.isNotEmpty) {
          final V2TimFriendInfoResult friendInfoResult = friendRes[0];
          currentChatUserInfo = V2TimGroupMemberFullInfo(
              userID: convID,
              faceUrl: friendInfoResult.friendInfo?.userProfile?.faceUrl,
              nickName: friendInfoResult.friendInfo?.userProfile?.nickName,
              friendRemark: friendInfoResult.friendInfo?.friendRemark);
        } else {
          final List<V2TimUserFullInfo>? userRes =
              await _friendshipServices.getUsersInfo(userIDList: [convID]);
          if (userRes != null && userRes.isNotEmpty) {
            final V2TimUserFullInfo userFullInfo = userRes[0];
            currentChatUserInfo = V2TimGroupMemberFullInfo(
              userID: convID,
              faceUrl: userFullInfo.faceUrl,
              nickName: userFullInfo.nickName,
            );
          }
        }
        _notify();
      });
    }

    // 语音消息连续播放新增逻辑 begin
    _setSoundSubscription();
    // 语音消息连续播放新增逻辑 end

    _isInit = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      markMessageAsRead();
    });
  }

  Future<bool> loadListForSpecificMessage({
    required int seq,
  }) async {
    List<V2TimMessage> msgList = [];
    haveMoreData = false;

    final previousResponse =
        await _messageService.getHistoryMessageListWithComplete(
            count: 20,
            getType: HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG,
            userID: conversationType == ConvType.c2c ? conversationID : null,
            groupID: conversationType == ConvType.group ? conversationID : null,
            lastMsgSeq: max(seq, 0));
    msgList = previousResponse?.messageList ?? [];
    haveMoreData = !(previousResponse?.isFinished ?? false);
    haveMoreLatestData = true;
    globalModel.setMessageListPosition(
        conversationID, HistoryMessagePosition.notShowLatest);

    msgList = await lifeCycle?.didGetHistoricalMessageList(msgList) ?? msgList;
    msgList.insert(
        msgList.length - 1,
        V2TimMessage(
            userID: '',
            isSelf: false,
            elemType: 101,
            msgID: msgList[0].msgID,
            seq: msgList[0].seq,
            timestamp: 9999));
    globalModel.setMessageList(conversationID, msgList,
        needResetNewMessageCount: false);

    if (chatConfig.isShowGroupReadingStatus &&
        conversationType == ConvType.group) {
      _getMsgReadReceipt(msgList);
    }
    if (chatConfig.isReportGroupReadingStatus &&
        conversationType == ConvType.group) {
      _setMsgReadReceipt(msgList);
    }

    return haveMoreData;
  }

  // 加载聊天记录
  Future<bool> loadChatRecord({
    HistoryMsgGetTypeEnum? getType,
    int lastMsgSeq = -1,
    required int count,
    String? lastMsgID,
    LoadDirection direction = LoadDirection.previous,
  }) async {
    try {
      // 根据加载方向设置是否还能继续加载更多消息
      direction == LoadDirection.latest
          ? haveMoreLatestData = false
          : haveMoreData = false;

      // 获取当前聊天对话的历史消息列表
      final currentRecordList = globalModel.messageListMap[conversationID];

      // 调用MessageService获取聊天记录
      final response = await _messageService.getHistoryMessageListWithComplete(
        count: count,
        getType: getType ??
            (direction == LoadDirection.previous
                ? HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG
                : HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_NEWER_MSG),
        userID: conversationType == ConvType.c2c ? conversationID : null,
        groupID: conversationType == ConvType.group ? conversationID : null,
        lastMsgID: lastMsgID,
        lastMsgSeq: lastMsgSeq,
      );

      if (response == null) {
        return false;
      }

      // 根据加载方向更新是否还能继续加载更多消息
      if (direction == LoadDirection.latest) {
        haveMoreLatestData = !response.isFinished;
      } else {
        haveMoreData = !response.isFinished;
      }
      _notify();

      // 根据lastMsgID判断是否为分页加载
      if (lastMsgID != null && currentRecordList != null) {
        List<V2TimMessage> messageList = response.messageList;
        List<V2TimMessage> newList = [];

        // 根据加载方向拼接消息列表
        if (direction == LoadDirection.latest) {
          globalModel.receivedNewMessageCount =
              globalModel.receivedMessageListCount + messageList.length;
          messageList = messageList.reversed.toList();
          newList = _combineMessageList(messageList, currentRecordList);
        } else {
          newList = _combineMessageList(currentRecordList, messageList);
        }

        // 处理新获取的消息列表后回调
        final List<V2TimMessage> msgList =
            await lifeCycle?.didGetHistoricalMessageList(newList) ?? newList;

        // 更新聊天记录到全局model
        globalModel.setMessageList(
          conversationID,
          msgList,
          needResetNewMessageCount: false,
        );
      } else {
        // 处理新获取的消息列表后回调
        List<V2TimMessage> receivedList = await lifeCycle
                ?.didGetHistoricalMessageList(response.messageList) ??
            response.messageList;
        globalModel.loadingMessage.remove(conversationID);

        // 更新聊天记录到全局model
        globalModel.setMessageList(
          conversationID,
          receivedList,
          needResetNewMessageCount: false,
        );
      }

      // 获取已读未读状态
      if (chatConfig.isShowGroupReadingStatus &&
          conversationType == ConvType.group &&
          response.messageList.isNotEmpty) {
        _getMsgReadReceipt(response.messageList);
      }
      if (chatConfig.isReportGroupReadingStatus &&
          conversationType == ConvType.group &&
          response.messageList.isNotEmpty) {
        _setMsgReadReceipt(response.messageList);
      }

      // 根据加载方向更新是否还能继续加载更多消息
      if (direction == LoadDirection.latest && !haveMoreLatestData) {
        globalModel.setMessageListPosition(
            conversationID, HistoryMessagePosition.inTwoScreen);
      }
      _notify();

      return haveMoreData;
    } catch (e) {
      // ignore: avoid_print
      outputLogger.i('loadChatRecord error: $e');
      return false;
    }
  }

// 拼接聊天记录
  List<V2TimMessage> _combineMessageList(
      List<V2TimMessage> first, List<V2TimMessage> second) {
    return [...first, ...second];
  }

  Future<bool> loadDataFromController({int? count}) {
    return loadChatRecord(
      count: count ?? HistoryMessageDartConstant.getCount, //20
    );
  }

  Future<V2TimValueCallback<List<V2TimMessageReceipt>>> getMessageReadReceipts(
      List<String> messageIDList) {
    return _messageService.getMessageReadReceipts(messageIDList: messageIDList);
  }

  _getMsgReadReceipt(List<V2TimMessage> message) async {
    final msgID = message
        .where((e) => (e.isSelf ?? true) && (e.needReadReceipt ?? false))
        .map((e) => e.msgID ?? '')
        .toList();
    if (msgID.isNotEmpty) {
      final res = await getMessageReadReceipts(msgID);
      if (res.code == 0) {
        final receiptList = res.data;
        if (receiptList != null) {
          for (var item in receiptList) {
            globalModel.messageReadReceiptMap[item.msgID!] = item;
          }
        }
      }
      _notify();
    }
  }

  translateText(V2TimMessage message) async {
    final String originText = message.textElem?.text ?? "";
    final String deviceLocale = TIM_getCurrentDeviceLocale();
    final String targetMessage = deviceLocale.split("-")[0];
    final translatedText =
        await _messageService.translateText(originText, targetMessage);

    final LocalCustomDataModel localCustomData = LocalCustomDataModel.fromMap(
        json.decode(TencentUtils.checkString(message.localCustomData) ?? "{}"));
    localCustomData.translatedText = translatedText;
    message.localCustomData = json.encode(localCustomData.toMap());
    globalModel.onMessageModified(message);
    TencentImSDKPlugin.v2TIMManager.v2TIMMessageManager.setLocalCustomData(
        msgID: message.msgID!, localCustomData: message.localCustomData ?? "");
  }

  _setMsgReadReceipt(List<V2TimMessage> message) async {
    final msgIDList = List<String>.empty(growable: true);
    for (var item in message) {
      final isSelf = item.isSelf ?? true;
      final needReadReceipt = item.needReadReceipt ?? false;
      final isRead = item.isRead ?? false;
      if (!isRead && !isSelf && needReadReceipt && item.msgID != null) {
        msgIDList.add(item.msgID!);
        item.needReadReceipt = false;
      }
    }
    if (msgIDList.isNotEmpty) {
      sendMessageReadReceipts(msgIDList);
    }
  }

  sendMessageReadReceipts(List<String> messageIDList) async {
    final res = await _messageService.sendMessageReadReceipts(
        messageIDList: messageIDList);
    return res;
  }

  markMessageAsRead() async {
    globalModel.unreadCountForConversation = 0;
    if (conversationType == ConvType.c2c) {
      return _messageService.markC2CMessageAsRead(userID: conversationID);
    }

    final res =
        await _messageService.markGroupMessageAsRead(groupID: conversationID);
    if (res.code == 10015) {
      isGroupExist = false;
    }
  }

  Future<void> loadSelfMemberInfo({required String groupID}) async {
    V2TimValueCallback<List<V2TimGroupMemberFullInfo>> getGroupMembersInfoRes =
        await TencentImSDKPlugin.v2TIMManager
            .getGroupManager()
            .getGroupMembersInfo(
      groupID: groupID,
      memberList: [selfModel.loginInfo?.userID ?? ""],
    );
    if (getGroupMembersInfoRes.code == 0) {
      final userList = getGroupMembersInfoRes.data;
      selfMemberInfo = userList
          ?.firstWhereOrNull((e) => e.userID == selfModel.loginInfo?.userID);
      _notify();
    }
    return;
  }

  Future<void> loadGroupMemberList(
      {required String groupID, int count = 100, String? seq}) async {
    final String? nextSeq = await _loadGroupMemberListFunction(
        groupID: groupID, seq: seq, count: count);
    if (nextSeq != null && nextSeq != "0" && nextSeq != "") {
      return await loadGroupMemberList(
          groupID: groupID, count: count, seq: nextSeq);
    } else {
      selfMemberInfo = groupMemberList
          ?.firstWhereOrNull((e) => e?.userID == selfModel.loginInfo?.userID);
      _notify();
    }
  }

  void _notify() {
    try {
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<String?> _loadGroupMemberListFunction(
      {required String groupID, int count = 100, String? seq}) async {
    if (seq == null || seq == "" || seq == "0") {
      groupMemberList?.clear();
    }
    try {
      final res = await _groupServices.getGroupMemberList(
          groupID: groupID,
          filter: GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_ALL,
          count: count,
          nextSeq: seq ?? groupMemberListSeq);
      final groupMemberListRes = res.data;
      if (res.code == 0 && groupMemberListRes != null) {
        final groupMemberListTemp = groupMemberListRes.memberInfoList ?? [];
        groupMemberList = [...?groupMemberList, ...groupMemberListTemp];
        groupMemberListSeq = groupMemberListRes.nextSeq ?? "0";
      } else if (res.code == 10010) {
        isGroupExist = false;
      } else if (res.code == 10007) {
        isNotAMember = true;
      }
      return groupMemberListRes?.nextSeq;
    } catch (e) {
      return "";
    }
  }

  Future<(V2TimGroupInfo?, GroupReceiptAllowType?)> loadGroupInfo(
      String groupID) async {
    final groupInfoList =
        await _groupServices.getGroupsInfo(groupIDList: [groupID]);
    if (groupInfoList != null && groupInfoList.isNotEmpty) {
      final groupRes = groupInfoList.first;
      if (groupRes.resultCode == 0) {
        _groupInfo = groupRes.groupInfo;

        const groupTypeMap = {
          "Meeting": GroupReceiptAllowType.meeting,
          "Public": GroupReceiptAllowType.public,
          "Work": GroupReceiptAllowType.work
        };
        _groupType = groupTypeMap[groupRes.groupInfo?.groupType];

        _notify();
        return (_groupInfo, _groupType);
      }
    }
    return (null, null);
  }

  Future<void> updateMessageFromController(
      {required String msgID, V2TimMessage? message}) async {
    V2TimMessage? newMessage = message ??
        await tools.getExistingMessageByID(
            msgID: msgID,
            conversationType: conversationType ?? ConvType.c2c,
            conversationID: conversationID);
    if (newMessage != null) {
      globalModel.onMessageModified(newMessage, conversationID);
    } else {
      loadChatRecord(
        count: HistoryMessageDartConstant.getCount,
      );
    }
  }

  Future<V2TimValueCallback<V2TimMessageChangeInfo>?> modifyMessage(
      {required V2TimMessage message}) async {
    return _messageService.modifyMessage(message: message);
  }

  Future<V2TimValueCallback<V2TimMessage>> _sendMessage({
    required String id,
    required String convID,
    required ConvType convType,
    V2TimMessage? messageInfo,
    OfflinePushInfo? offlinePushInfo,
    bool? onlineUserOnly = false,
    MessagePriorityEnum priority = MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
    bool? isExcludedFromUnreadCount,
    bool? needReadReceipt,
    String? cloudCustomData,
    String? localCustomData,
    bool? isEditStatusMessage = false,
  }) async {
    String receiver = convType == ConvType.c2c ? convID : '';
    String groupID = convType == ConvType.group ? convID : '';
    if (convType == ConvType.group && _groupType == null) {
      await loadGroupInfo(groupID);
    }
    final oldGroupType = _groupType != null
        ? GroupReceptAllowType.values[_groupType!.index]
        : null;
    if (messageInfo != null) {
      setLoadingMessageMap(convID, messageInfo);
    }
    final sendMsgRes = await _messageService.sendMessage(
      priority: priority,
      localCustomData: localCustomData,
      isExcludedFromUnreadCount: isExcludedFromUnreadCount ?? false,
      id: id,
      receiver: receiver,
      needReadReceipt: needReadReceipt ??
          chatConfig.isShowGroupReadingStatus &&
              convType == ConvType.group &&
              ((chatConfig.groupReadReceiptPermissionList != null &&
                      chatConfig.groupReadReceiptPermissionList!
                          .contains(_groupType)) ||
                  (chatConfig.groupReadReceiptPermisionList != null &&
                      chatConfig.groupReadReceiptPermisionList!
                          .contains(oldGroupType))),
      groupID: groupID,
      offlinePushInfo: offlinePushInfo,
      onlineUserOnly: onlineUserOnly ?? false,
      cloudCustomData: cloudCustomData ??
          (showC2cMessageEditStatus == true
              ? json.encode({
                  "messageFeature": {
                    "needTyping": 1,
                    "version": 1,
                  }
                })
              : ""),
    );
    removeSendingMessageID(id);
    if (isEditStatusMessage == false &&
        globalModel.getMessageListPosition(conversationID) !=
            HistoryMessagePosition.notShowLatest) {
      globalModel.updateMessage(
          sendMsgRes, convID, id, convType, groupType, setInputField);
    }
    if (lifeCycle?.messageDidSend != null) {
      lifeCycle!.messageDidSend(sendMsgRes);
    }

    return sendMsgRes;
  }

  List<V2TimMessage> getOriginMessageList() {
    return globalModel.messageListMap[conversationID] ?? [];
  }

  int getConversationUnreadCount() {
    return globalModel.unreadCountForConversation;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendTextAtMessage(
      {required String text,
      required String convID,
      required ConvType convType,
      required List<String> atUserList}) async {
    if (text.isEmpty) {
      return null;
    }
    final textATMessageInfo = await _messageService.createTextAtMessage(
        text: text, atUserList: atUserList);
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final messageInfo = textATMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender =
          tools.setUserInfoForMessage(messageInfo, textATMessageInfo.id!);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      if (globalModel.getMessageListPosition(conversationID) !=
          HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }

      return _sendMessage(
          convID: convID,
          id: textATMessageInfo.id as String,
          convType: ConvType.group,
          offlinePushInfo: tools.buildMessagePushInfo(
              textATMessageInfo.messageInfo!, convID, convType));
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendCustomMessage(
      {required String data,
      required String convID,
      required ConvType convType}) async {
    final customMessageInfo =
        await _messageService.createCustomMessage(data: data);
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final messageInfo = customMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender =
          tools.setUserInfoForMessage(messageInfo, customMessageInfo.id!);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      if (globalModel.getMessageListPosition(conversationID) !=
          HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }

      return _sendMessage(
          convID: convID,
          id: customMessageInfo.id as String,
          convType: convType,
          offlinePushInfo: tools.buildMessagePushInfo(
              customMessageInfo.messageInfo!, convID, convType));
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendFaceMessage(
      {required int index,
      required String data,
      required String convID,
      required ConvType convType}) async {
    final faceMessageInfo =
        await _messageService.createFaceMessage(index: index, data: data);
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final messageInfo = faceMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender =
          tools.setUserInfoForMessage(messageInfo, faceMessageInfo.id!);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      if (globalModel.getMessageListPosition(conversationID) !=
          HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }

      return _sendMessage(
          convID: convID,
          id: faceMessageInfo.id as String,
          convType: convType,
          messageInfo: messageInfoWithSender,
          offlinePushInfo: tools.buildMessagePushInfo(
              faceMessageInfo.messageInfo!, convID, convType));
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendSoundMessage({
    required String soundPath,
    required int duration,
    required String convID,
    required ConvType convType,
  }) async {
    final soundMessageInfo = await _messageService.createSoundMessage(
        soundPath: soundPath, duration: duration);
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final messageInfo = soundMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender =
          tools.setUserInfoForMessage(messageInfo, soundMessageInfo.id!);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      if (globalModel.getMessageListPosition(conversationID) !=
          HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }

      return _sendMessage(
        convID: convID,
        id: soundMessageInfo.id as String,
        convType: convType,
        offlinePushInfo: tools.buildMessagePushInfo(
            soundMessageInfo.messageInfo!, convID, convType),
      );
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendReplyMessage({
    required String text,
    required String convID,
    required ConvType convType,
    List<String>? atUserIDList,
  }) async {
    if (text.isEmpty) {
      return null;
    }
    if (_repliedMessage != null) {
      V2TimMsgCreateInfoResult? textMessageInfo =
          await _messageService.createTextMessage(text: text);
      if (atUserIDList != null && atUserIDList.isNotEmpty) {
        textMessageInfo = await _messageService.createTextAtMessage(
            text: text, atUserList: atUserIDList);
      }
      final V2TimMessage? messageInfo = textMessageInfo!.messageInfo;
      final receiver = convType == ConvType.c2c ? convID : '';
      final groupID = convType == ConvType.group ? convID : '';
      final oldGroupType = _groupType != null
          ? GroupReceptAllowType.values[_groupType!.index]
          : null;
      if (messageInfo != null) {
        V2TimMessage messageInfoWithSender =
            tools.setUserInfoForMessage(messageInfo, textMessageInfo.id!);
        messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
        addSendingMessageID(messageInfo.id);
        final hasNickName = _repliedMessage?.nickName != null &&
            _repliedMessage?.nickName != "";
        final cloudCustomData = {
          "messageReply": {
            "messageID": _repliedMessage!.msgID,
            "messageAbstract": tools.getMessageAbstract(
                _repliedMessage!, abstractMessageBuilder),
            "messageSender": hasNickName
                ? _repliedMessage!.nickName
                : _repliedMessage?.sender,
            "messageType": _repliedMessage?.elemType,
            "version": 1
          }
        };
        messageInfoWithSender.cloudCustomData = json.encode(cloudCustomData);
        List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);

        _repliedMessage = null;
        final sendMsgRes = await _messageService.sendMessage(
            cloudCustomData:
                TencentUtils.checkString(messageInfoWithSender?.cloudCustomData) ??
                    json.encode(cloudCustomData),
            id: textMessageInfo.id as String,
            offlinePushInfo: tools.buildMessagePushInfo(
                messageInfoWithSender, convID, convType),
            needReadReceipt: chatConfig.isShowGroupReadingStatus &&
                convType == ConvType.group &&
                ((chatConfig.groupReadReceiptPermissionList != null &&
                        chatConfig.groupReadReceiptPermissionList!
                            .contains(_groupType)) ||
                    (chatConfig.groupReadReceiptPermisionList != null &&
                        chatConfig.groupReadReceiptPermisionList!
                            .contains(oldGroupType))),
            groupID: groupID,
            receiver: receiver);
        _notify();
        globalModel.updateMessage(sendMsgRes, convID,
            messageInfoWithSender.id ?? "", convType, groupType, setInputField);
        if (lifeCycle?.messageDidSend != null) {
          lifeCycle!.messageDidSend(sendMsgRes);
        }
        return sendMsgRes;
      }
    }
    return null;
  }

  double getFileSize(File file) {
    int sizeInBytes = file.lengthSync();
    double sizeInMb = sizeInBytes / (1024 * 1024);
    return sizeInMb;
  }

  Future<String> getTempPath() async {
    final id = _uuid.v4();
    return getTemporaryDirectory().then((appDocDir) {
      String filePath = appDocDir.path + id + ".jpeg";
      return filePath;
    });
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendImageMessage(
      {String? imagePath,
      String? imageName,
      required String convID,
      dynamic inputElement,
      required ConvType convType}) async {
    String? image;
    if ((PlatformUtils().isAndroid || PlatformUtils().isIOS) &&
        imagePath != null &&
        imagePath.isNotEmpty) {
      try {
        final size = getFileSize(File(imagePath));
        final format =
            imagePath.split(".")[imagePath.split(".").length - 1].toLowerCase();
        if (size > 20 ||
            (format != "jpg" && format != "png" && format != "gif")) {
          final target = await getTempPath();
          final result = await FlutterImageCompress.compressAndGetFile(
              imagePath, target,
              format: CompressFormat.jpeg, quality: 85);
          image = result?.path;
        }
        // ignore: empty_catches
      } catch (e) {}
    }
    final imageMessageInfo = await _messageService.createImageMessage(
        imageName: imageName,
        imagePath: image ?? imagePath,
        inputElement: inputElement);
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final messageInfo = imageMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender =
          tools.setUserInfoForMessage(messageInfo, imageMessageInfo.id);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      if (globalModel.getMessageListPosition(conversationID) !=
          HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }

      return _sendMessage(
        convID: convID,
        messageInfo: messageInfoWithSender,
        id: imageMessageInfo.id as String,
        convType: convType,
        offlinePushInfo: tools.buildMessagePushInfo(
            imageMessageInfo.messageInfo!, convID, convType),
      );
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendVideoMessage(
      {String? videoPath,
      int? duration,
      String? snapshotPath,
      required String convID,
      required ConvType convType,
      dynamic inputElement}) async {
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final videoMessageInfo = await _messageService.createVideoMessage(
        videoPath: videoPath,
        type: videoPath != null
            ? videoPath.split(".")[videoPath.split(".").length - 1]
            : 'mp4',
        duration: duration,
        inputElement: inputElement,
        snapshotPath: snapshotPath);
    final messageInfo = videoMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender =
          tools.setUserInfoForMessage(messageInfo, videoMessageInfo.id);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      if (globalModel.getMessageListPosition(conversationID) !=
          HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }

      return _sendMessage(
        convID: convID,
        messageInfo: messageInfoWithSender,
        id: videoMessageInfo.id as String,
        convType: convType,
        offlinePushInfo: tools.buildMessagePushInfo(
            videoMessageInfo.messageInfo!, convID, convType),
      );
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendFileMessage(
      {String? filePath,
      String? fileName,
      int? size,
      dynamic inputElement,
      required String convID,
      required ConvType convType}) async {
    if (await tools.hasZeroSize(filePath ?? "")) {
      _coreServices.callOnCallback(TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: "不支持 0KB 文件的传输",
          infoCode: 6660417));
      return null;
    }
    /////////////  处理桌面端路径的问题
    if (Platform.isMacOS || Platform.isWindows) {
      if (filePath != null && filePath.isNotEmpty) {
        fileName = path
            .split(filePath)
            .last;
      }
    }
    //////////////
    final fileMessageInfo = await _messageService.createFileMessage(
        inputElement: inputElement,
        fileName: fileName ?? filePath?.split('/').last ?? "",
        filePath: filePath);
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final messageInfo = fileMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender =
          tools.setUserInfoForMessage(messageInfo, fileMessageInfo.id);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      messageInfoWithSender.fileElem!.fileSize = size;
      if (globalModel.getMessageListPosition(conversationID) !=
          HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }

      return _sendMessage(
        convID: convID,
        messageInfo: messageInfoWithSender,
        id: fileMessageInfo.id as String,
        convType: convType,
        offlinePushInfo: tools.buildMessagePushInfo(
            fileMessageInfo.messageInfo!, convID, convType),
      );
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendLocationMessage(
      {required String desc,
      required double longitude,
      required double latitude,
      required String convID,
      required ConvType convType}) async {
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final locationMessageInfo = await _messageService.createLocationMessage(
        desc: desc, longitude: longitude, latitude: latitude);
    final messageInfo = locationMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender =
          tools.setUserInfoForMessage(messageInfo, locationMessageInfo.id);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      if (globalModel.getMessageListPosition(conversationID) !=
          HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }
      return _sendMessage(
        convID: convID,
        id: locationMessageInfo.id as String,
        convType: convType,
        offlinePushInfo: tools.buildMessagePushInfo(
            locationMessageInfo.messageInfo!, convID, convType),
      );
    }
    return null;
  }

  /// 逐条转发
  sendForwardMessage({
    required List<V2TimConversation> conversationList,
  }) async {
    final selectedMessages = List.from(_multiSelectedMessageList);
    if (conversationType == ConvType.c2c) {
      selectedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else if (conversationType == ConvType.group) {
      selectedMessages.sort((a, b) => a.seq.compareTo(b.seq));
    }
    for (var conversation in conversationList) {
      final convID = conversation.groupID ?? conversation.userID ?? "";
      final convType = conversation.type;
      for (var message in selectedMessages) {
        final forwardMessageInfo = await _messageService.createForwardMessage(msgID: message.msgID!);
        final messageInfo = forwardMessageInfo!.messageInfo;
        if (messageInfo != null) {
          tools.setUserInfoForMessage(messageInfo, forwardMessageInfo.id);
          messageInfo.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
          addSendingMessageID(messageInfo.id);
          await Future.delayed(Duration(milliseconds: 100), () {
            _sendMessage(
              id: forwardMessageInfo.id!,
              convID: convID,
              convType: convType == 1 ? ConvType.c2c : ConvType.group,
              offlinePushInfo: tools.buildMessagePushInfo(
                  forwardMessageInfo.messageInfo!,
                  convID,
                  convType == 1 ? ConvType.c2c : ConvType.group),
            );
          });
        }
      }
    }
  }

  /// 合并转发
  Future<V2TimValueCallback<V2TimMessage>?> sendMergerMessage({
    required List<V2TimConversation> conversationList,
    required String title,
    required List<String> abstractList,
    required BuildContext context,
  }) async {
    final List<String> msgIDList = _multiSelectedMessageList
        .map((e) => e.msgID ?? "")
        .where((element) => element != "")
        .toList();
    for (var conversation in conversationList) {
      final convID = conversation.groupID ?? conversation.userID ?? "";
      final convType = conversation.type;
      final mergerMessageInfo = await _messageService.createMergerMessage(
          msgIDList: msgIDList,
          title: title,
          abstractList: abstractList,
          compatibleText: TIM_t("该版本不支持此消息"));
      final messageInfo = mergerMessageInfo!.messageInfo;
      if (messageInfo != null) {
        tools.setUserInfoForMessage(messageInfo, mergerMessageInfo.id);
        messageInfo.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
        addSendingMessageID(messageInfo.id);
        _sendMessage(
          id: mergerMessageInfo.id!,
          convID: convID,
          convType: convType == 1 ? ConvType.c2c : ConvType.group,
          offlinePushInfo: tools.buildMessagePushInfo(
              mergerMessageInfo.messageInfo!,
              convID,
              convType == 1 ? ConvType.c2c : ConvType.group),
        );
      }
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> reSendFailMessage({
    required V2TimMessage message,
    required String convID,
    required ConvType convType,
  }) async {
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    if (currentHistoryMsgList.isEmpty) {
      return null;
    }

    int messageIndex = currentHistoryMsgList.indexWhere((element) => element.msgID == message.msgID);
    if (messageIndex != -1) {
      // 取出界面的消息列表，设置转发的这条消息状态为 sending
      currentHistoryMsgList[messageIndex].status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(message.msgID);
      globalModel.setMessageList(convID, currentHistoryMsgList);
      // 重发该消息
      final res = await _messageService.reSendMessage(
          msgID: message.msgID ?? "", onlineUserOnly: false);
      removeSendingMessageID(message.msgID ?? "");
      final messageInfo = res.data;
      // 重发完成后，更新消息列表中的这条消息
      currentHistoryMsgList[messageIndex] = messageInfo!;
      globalModel.setMessageList(convID, currentHistoryMsgList);
      return res;
    }

    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendTextMessage(
      {required String text,
      required String convID,
      required ConvType convType}) async {
    if (text.isEmpty) {
      return null;
    }
    final textMessageInfo = await _messageService.createTextMessage(text: text);
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final messageInfo = textMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender =
          tools.setUserInfoForMessage(messageInfo, textMessageInfo.id!);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      if (globalModel.getMessageListPosition(conversationID) !=
          HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }

      return _sendMessage(
          convID: convID,
          id: textMessageInfo.id as String,
          convType: convType,
          offlinePushInfo: tools.buildMessagePushInfo(
              textMessageInfo.messageInfo!, convID, convType));
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?>? sendMessageFromController({
    required V2TimMessage? messageInfo,

    /// Offline push info
    OfflinePushInfo? offlinePushInfo,
    MessagePriorityEnum priority = MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
    bool? onlineUserOnly,
    bool? isExcludedFromUnreadCount,
    bool? needReadReceipt,
    String? cloudCustomData,
    String? localCustomData,
  }) {
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    if (messageInfo != null) {
      final messageInfoWithSender = messageInfo.sender == null
          ? tools.setUserInfoForMessage(messageInfo, messageInfo.id!)
          : messageInfo;
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      if (globalModel.getMessageListPosition(conversationID) !=
          HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [
          messageInfoWithSender,
          ...currentHistoryMsgList
        ];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
      }

      return _sendMessage(
        priority: priority,
        onlineUserOnly: onlineUserOnly,
        isExcludedFromUnreadCount: isExcludedFromUnreadCount,
        needReadReceipt: needReadReceipt,
        cloudCustomData: cloudCustomData,
        localCustomData: localCustomData,
        convID: conversationID,
        id: messageInfo.id as String,
        convType: conversationType ?? ConvType.c2c,
        offlinePushInfo: offlinePushInfo ??
            tools.buildMessagePushInfo(
                messageInfo, conversationID, conversationType ?? ConvType.c2c),
      );
    }
    return null;
  }

  deleteMsg(String msgID, {String? id, Object? webMessageInstance}) async {
    if (lifeCycle?.shouldDeleteMessage != null &&
        await lifeCycle!.shouldDeleteMessage(msgID) == false) {
      return;
    }
    final messageList = getOriginMessageList();
    final res = await _messageService.deleteMessageFromLocalStorage(
        msgID: msgID, webMessageInstance: webMessageInstance);
    if (res.code == 0) {
      messageList.removeWhere((element) {
        return element.msgID == msgID || (id != null && element.id == id);
      });
    }
    globalModel.setMessageList(conversationID, messageList);
  }

  clearHistory() async {
    if (lifeCycle?.shouldClearHistoricalMessageList != null &&
        await lifeCycle!.shouldClearHistoricalMessageList(conversationID) ==
            false) {
      return;
    }
    globalModel.setMessageList(conversationID, []);
  }

  Future<Object?> revokeMsg(String msgID, bool isAdmin,
      [Object? webMessageInstance]) async {
    if (chatConfig.isGroupAdminRecallEnabled) {
      final V2TimMessage? message = globalModel.messageListMap[conversationID]
          ?.firstWhere((element) => element.msgID == msgID);
      if (message != null) {
        if (PlatformUtils().isWeb) {
          final decodedMessage = jsonDecode(message.messageFromWeb!);
          decodedMessage["cloudCustomData"] =
              jsonEncode({"isRevoke": true, "revokeByAdmin": isAdmin});
          message.messageFromWeb = jsonEncode(decodedMessage);
        } else {
          message.cloudCustomData =
              jsonEncode({"isRevoke": true, "revokeByAdmin": isAdmin});
        }
        return await modifyMessage(message: message);
      }
    }

    final res = await _messageService.revokeMessage(
        msgID: msgID, webMessageInstance: webMessageInstance);
    if (res.code == 0) {
      globalModel.onMessageRevoked(msgID, conversationID);
    }
    return res;
  }

  addToMultiSelectedMessageList(V2TimMessage message) {
    _multiSelectedMessageList.add(message);
    _notify();
  }

  removeFromMultiSelectedMessageList(V2TimMessage message) {
    _multiSelectedMessageList.remove(message);
    _notify();
  }

  deleteSelectedMsg() async {
    List<V2TimMessage> messageList = getOriginMessageList();
    final msgIDs = _multiSelectedMessageList
        .map((e) => e.msgID ?? "")
        .where((element) => element != "")
        .toList();
    final webMessageInstanceList = _multiSelectedMessageList
        .map((e) => e.messageFromWeb)
        .where((element) => element != null)
        .toList();

    final res = await _messageService.deleteMessages(
        msgIDs: msgIDs, webMessageInstanceList: webMessageInstanceList);
    if (res.code == 0) {
      for (var msgID in msgIDs) {
        messageList.removeWhere((element) => element.msgID == msgID);
      }
      globalModel.setMessageList(conversationID, messageList);
    }
  }

  updateMultiSelectStatus(bool isSelect) {
    _isMultiSelect = isSelect;
    if (!isSelect) {
      _multiSelectedMessageList.clear();
    }
    _notify();
  }

  Future<V2TimValueCallback<V2TimGroupMessageReadMemberList>>
      getGroupMessageReadMemberList(String messageID,
          GetGroupMessageReadMemberListFilter fileter, int nextSeq) async {
    final res = await _messageService.getGroupMessageReadMemberList(
        nextSeq: nextSeq, messageID: messageID, filter: fileter);
    return res;
  }

  Future<List<V2TimMessage>?> downloadMergerMessage(String msgID) async {
    await _messageService.getHistoryMessageList(
      count: 100,
      getType: HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG,
      userID: conversationType == ConvType.c2c ? conversationID : null,
      groupID: conversationType == ConvType.group ? conversationID : null,
    );
    return _messageService.downloadMergerMessage(msgID: msgID);
  }

  Future<V2TimMessage?> findMessage(String msgID) async {
    List<V2TimMessage> messageList = getOriginMessageList();
    final repliedMessage =
        messageList.where((element) => element.msgID == msgID).toList();
    if (repliedMessage.isNotEmpty) {
      return repliedMessage.first;
    }
    final message = await _messageService.findMessages(messageIDList: [msgID]);
    if (message != null && message.isNotEmpty) {
      return message.first;
    }
    return null;
  }

  showLatestUnread() {
    markMessageAsRead();
    globalModel.setMessageListPosition(
        conversationID, HistoryMessagePosition.bottom);
  }

  // 添加发送中的消息的 id 或者 msgID(id 不存在时使用 msgID)
  void addSendingMessageID(String? id) {
    if (id?.isNotEmpty == true) {
      _sendingMessageIDList.add(id!);
    }
  }

  // 移除发送中的消息的 id 或者 msgID(id 不存在时使用 msgID)
  void removeSendingMessageID(String id) {
    bool hasID = _sendingMessageIDList.contains(id);
    if (hasID) {
      _sendingMessageIDList.remove(id);
    }
  }

  // 内存中有发送中的消息的 id 或者 msgID(id 不存在时使用 msgID)
  bool hasSendingMessageID(String id) {
    return _sendingMessageIDList.contains(id);
  }

  @override
  void dispose() {
    // 语音消息连续播放新增逻辑 begin
    cancelSoundSubscription();
    // 语音消息连续播放新增逻辑 end

    globalModel.clearCurrentConversation();
    _isInit = false;
    super.dispose();
  }

  // 语音消息连续播放新增逻辑 begin
  bool isPlaying = false;
  bool findNext = true;
  StreamSubscription<Object>? subscriptionNew;
  void cusNotifyListeners() {
    if (_isInit) {
      notifyListeners();
    }
  }
  // 语音消息连续播放新增逻辑 end
}

extension TUIChatSeparateViewModelAudioPlay on TUIChatSeparateViewModel {
  List<V2TimMessage> get soundMessageList =>
      globalModel.getSoundMessageList(conversationID);

  void _setSoundSubscription() {
    subscriptionNew = SoundPlayer.playStateListener(
      listener: (PlayerState state) {
        if (state == PlayerState.completed) {
          if (!findNext) {
            stopAndResetAudio();
            return;
          }

          isPlaying = false;
          final int index =
              soundMessageList.indexWhere((e) => e.msgID == currentPlayedMsgId);
          if (index == -1) {
            stopAndResetAudio();
            return;
          }

          if (index < soundMessageList.length - 1) {
            final currentMessage = soundMessageList[index + 1];

            // 遇到的音频已读，直接返回，不再往下进行
            if (currentMessage.localCustomInt ==
                HistoryMessageDartConstant.read) {
              stopAndResetAudio();
              return;
            }

            if (currentMessage.msgID != null) {
              _currentPlayedMsgId = currentMessage.msgID!;

              // 标记已读
              globalModel.setLocalCustomInt(
                currentPlayedMsgId,
                HistoryMessageDartConstant.read,
                conversationID,
              );

              // 直接使用 localUrl
              bool isLocal = false;
              String url = currentMessage.soundElem?.localUrl ?? '';
              isLocal = url.isNotEmpty;

              playSound(
                msgID: currentMessage.msgID!,
                url: url,
                isLocal: isLocal,
                currentMessage: currentMessage,
              );
            } else {
              _currentPlayedMsgId = "";
            }
          } else {
            _currentPlayedMsgId = "";
          }

          cusNotifyListeners();
        }
      },
    );
  }

  void cancelSoundSubscription() {
    if (isPlaying) {
      stopAndResetAudio(notify: false);
    }
    subscriptionNew?.cancel();
  }

  // 音频文件是否已下载
  String _soundLocalFilePath(V2TimMessage message) {
    if (PlatformUtils().isWeb) {
      return '';
    }

    String savePath = TencentUtils.checkString(
            globalModel.getFileMessageLocation(message.msgID)) ??
        TencentUtils.checkString(message.soundElem?.localUrl) ??
        message.soundElem?.path ??
        '';

    File f = File(savePath);
    if (f.existsSync()) {
      return savePath;
    }
    return '';
  }

  Future<void> playSound({
    required String msgID,
    required String url,
    required bool isLocal,
    bool findNext = true,
    required V2TimMessage currentMessage,
  }) async {
    this.findNext = findNext;

    String playUrl = url;
    bool playLocal = isLocal;

    debugPrint('playSound url: $playUrl isLocal: $playLocal');

    if (!playLocal || playUrl.isEmpty) {
      // 获取已下载路径
      playUrl = _soundLocalFilePath(currentMessage);

      if (playUrl.isNotEmpty) {
        playLocal = true;
      } else {
        try {
          final response = await _messageService.getMessageOnlineUrl(
            msgID: msgID,
          );
          if (response.data != null) {
            playUrl = response.data!.soundElem?.localUrl ?? '';
            if (playUrl.isEmpty) {
              playUrl = response.data!.soundElem?.url ?? '';
            } else {
              playLocal = true;
            }
          }
          debugPrint(
              'playSound getMessageOnlineUrl url: $playUrl isLocal: $playLocal');
        } catch (e) {
          _coreServices.callOnCallback(
            TIMCallback(
              type: TIMCallbackType.INFO,
              infoRecommendText: '音频下载失败，请稍后再试',
            ),
          );
          return;
        }
      }
    }

    debugPrint('playSound play isEmpty url: $playUrl isLocal: $playLocal');

    if (!playLocal) {
      _coreServices.callOnCallback(
        TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: '音频暂未下载完成,请稍后再试',
        ),
      );

      _messageService.downloadMessage(
          msgID: msgID, messageType: 4, imageType: 0, isSnapshot: false);

      return;
    }

    if (playUrl.isEmpty) {
      stopAndResetAudio();
      _coreServices.callOnCallback(
        TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: '音频播放地址为空，请稍后再试',
        ),
      );
      return;
    }

    if (isPlaying && msgID == currentPlayedMsgId) {
      debugPrint(
          'playSound play url: $playUrl isLocal: $playLocal isPlaying: $isPlaying');
      stopAndResetAudio();
    } else {
      // 非同一个音频：停止上一个
      if (msgID != currentPlayedMsgId) {
        stopAndResetAudio(notify: false);
      }
      try {
        debugPrint('playSound play url: $playUrl isLocal: $playLocal');
        if (playLocal) {
          // _coreServices.callOnCallback(
          //   TIMCallback(
          //       type: TIMCallbackType.API_ERROR,
          //       errorMsg: '播放本地音频',
          //       errorCode: 1),
          // );
          SoundPlayer.playWith(source: DeviceFileSource(playUrl));
        } else {
          // _coreServices.callOnCallback(
          //   TIMCallback(
          //       type: TIMCallbackType.API_ERROR,
          //       errorMsg: '播放网络音频',
          //       errorCode: 2),
          // );
          SoundPlayer.play(url: playUrl);
        }
      } catch (e) {
        debugPrint(
            'playSound error: msgID-$msgID\nurl-$playUrl\nisLocal-$playLocal');
        _coreServices.callOnCallback(
          TIMCallback(
            type: TIMCallbackType.API_ERROR,
            errorMsg: TIM_t(
                'playSound error: msgID-$msgID\nurl-$playUrl\nisLocal-$playLocal'),
            errorCode: -1,
          ),
        );
        return;
      }
      isPlaying = true;
      _currentPlayedMsgId = msgID;
      cusNotifyListeners();
    }
  }

  stopAndResetAudio({
    bool notify = true,
  }) {
    SoundPlayer.stop();
    isPlaying = false;
    _currentPlayedMsgId = "";
    if (notify) {
      cusNotifyListeners();
    }
  }
}

////////////// 自定义方法 //////////////
extension CusMethods on TUIChatSeparateViewModel {
  convertVoiceToText(
      V2TimMessage message, TUIChatSeparateViewModel model) async {
    final soundElem = message.soundElem;
    // 不是语音消息，直接返回
    if (soundElem == null) return;
    final msgID = message.msgID ?? '';
    if (msgID.isEmpty) return;

    String convertVoiceToText = "";

    if (model.chatConfig.onVoiceToWord != null) {
      convertVoiceToText = await model.chatConfig.onVoiceToWord!.call(message);
    } else {
      convertVoiceToText = await _messageService.convertVoiceToText(
        msgID,
        // 如果您的主流用户使用中、英文居多，language 参数可传空字符串，此时我们默认使用中英模型识别
        '',
      );
    }
    final LocalCustomDataModel localCustomData = LocalCustomDataModel.fromMap(
      json.decode(TencentUtils.checkString(message.localCustomData) ?? "{}"),
    );
    localCustomData.convertVoiceToText = convertVoiceToText;
    message.localCustomData = json.encode(localCustomData.toMap());
    globalModel.onMessageModified(message);
    TencentImSDKPlugin.v2TIMManager.v2TIMMessageManager.setLocalCustomData(
      msgID: message.msgID!,
      localCustomData: message.localCustomData ?? "",
    );
  }
}
////////////// 自定义方法 //////////////
