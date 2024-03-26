import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/group/group_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/optimize_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';

class AtMemberPanel extends StatefulWidget {
  /// messageList widget scroll controller
  final AutoScrollController atMemberPanelScroll;

  final ValueChanged<V2TimGroupMemberFullInfo> onSelectMember;

  final TUIChatSeparateViewModel chatModel;

  // final TextFieldWebController textFieldWebController;
  const AtMemberPanel(
      // this.textFieldWebController,
      {
    Key? key,
    required this.atMemberPanelScroll,
    required this.onSelectMember,
    required this.chatModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AtMemberPanelState();
  }
}

_getShowName(V2TimGroupMemberFullInfo? item) {
  return TencentUtils.checkStringWithoutSpace(item?.nameCard) ??
      TencentUtils.checkStringWithoutSpace(item?.nickName) ??
      TencentUtils.checkStringWithoutSpace(item?.userID);
}

class _AtMemberPanelState extends TIMUIKitState<AtMemberPanel> {
  final GroupServices _groupServices = serviceLocator<GroupServices>();
  late TUIChatSeparateViewModel _chatModel;

  List<V2TimGroupMemberFullInfo?> _groupMemberList = [];
  String _nextSeq = '';

  bool _isLoading = false;

  Future<void> _getMemberList() async {
    if (_nextSeq == '0') return;
    final groupID = _chatModel.groupInfo?.groupID ?? '';
    if (groupID.isEmpty) return;
    if (_isLoading) return;

    try {
      _isLoading = true;
      final res = await _groupServices.getGroupMemberList(
        groupID: groupID,
        filter: GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_ALL,
        count: 20,
        nextSeq: _nextSeq.isEmpty ? '0' : _nextSeq,
      );
      final groupMemberListRes = res.data;

      if (res.code == 0 && groupMemberListRes != null) {
        final groupMemberListTemp = groupMemberListRes.memberInfoList ?? [];
        _groupMemberList = [..._groupMemberList, ...groupMemberListTemp];
        _groupMemberList.sort(
            (V2TimGroupMemberFullInfo? userA, V2TimGroupMemberFullInfo? userB) {
          final isUserAIsGroupAdmin = userA?.role == 300;
          final isUserAIsGroupOwner = userA?.role == 400;

          final isUserBIsGroupAdmin = userB?.role == 300;
          final isUserBIsGroupOwner = userB?.role == 400;

          final String userAName = _getShowName(userA);
          final String userBName = _getShowName(userB);

          if (isUserAIsGroupOwner != isUserBIsGroupOwner) {
            return isUserAIsGroupOwner ? -1 : 1;
          }

          if (isUserAIsGroupAdmin != isUserBIsGroupAdmin) {
            return isUserAIsGroupAdmin ? -1 : 1;
          }

          return userAName.compareTo(userBName);
        });
        _nextSeq = groupMemberListRes.nextSeq ?? '0';
        if (mounted) setState(() {});
      }
      _isLoading = false;
    } catch (e) {
      debugPrint('getGroupMemberList error: $e');
      _isLoading = false;
    }
  }

  @override
  void initState() {
    _chatModel = widget.chatModel;
    _getMemberList();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AtMemberPanel oldWidget) {
    if (oldWidget.chatModel.groupInfo?.groupID !=
        widget.chatModel.groupInfo?.groupID) {
      _getMemberList();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;

    final double positionX = _chatModel.atPositionX;
    final double positionY = _chatModel.atPositionY;
    final int activeIndex = _chatModel.activeAtIndex;

    if (activeIndex == -1 || _groupMemberList.isEmpty) {
      return Container();
    }

    final throteFunction =
        OptimizeUtils.throttle((ScrollNotification notification) {
      final pixels = notification.metrics.pixels;
      // 总像素高度
      final maxScrollExtent = notification.metrics.maxScrollExtent;
      // 滑动百分比
      final progress = pixels / maxScrollExtent;
      if (progress >= 0.9) {
        _getMemberList();
      }
    }, 300);

    return Positioned(
      left: positionX,
      bottom: positionY,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 170, maxWidth: 170),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: const Color(0xFFE5E6E9)),
        ),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            throteFunction(notification);
            return true;
          },
          child: Scrollbar(
            controller: widget.atMemberPanelScroll,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _groupMemberList.length,
              controller: widget.atMemberPanelScroll,
              itemBuilder: ((context, index) {
                final memberItem = _groupMemberList[index];
                if (memberItem == null) {
                  return AutoScrollTag(
                    key: ValueKey(index),
                    controller: widget.atMemberPanelScroll,
                    index: index,
                  );
                }
                final showName = _getShowName(memberItem);
                final isAtAll = memberItem.userID == "__kImSDK_MesssageAtALL__";
                return AutoScrollTag(
                  key: ValueKey(index),
                  controller: widget.atMemberPanelScroll,
                  index: index,
                  child: Material(
                    color: theme.wideBackgroundColor,
                    child: InkWell(
                      onTap: () {
                        _chatModel.activeAtIndex = index;
                        widget.onSelectMember(memberItem);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: activeIndex == index
                            ? theme.weakBackgroundColor
                            : theme.wideBackgroundColor,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Avatar(
                                faceUrl: memberItem.faceUrl ?? "",
                                type: 1,
                                showName: showName,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                isAtAll
                                    ? "$showName(${_groupMemberList.length - 1})"
                                    : showName,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: memberItem.role == 400 ||
                                          memberItem.role == 300
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  color: memberItem.role == 400 ||
                                          memberItem.role == 300
                                      ? theme.primaryColor
                                      : theme.darkTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
