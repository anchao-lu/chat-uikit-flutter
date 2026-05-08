// ignore_for_file:  avoid_print, unused_import

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';

import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';

import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/permission.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/sound_record.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_callback.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';

import 'bases/kx_bar_visualizer.dart';
import 'first/kx_first_bottom_widget.dart';
import 'first/kx_first_center.dart';
import 'second/kx_chat_sound_to_word_bubble.dart';
import 'second/kx_icon_widget.dart';
import 'second/kx_second_bottom_widget.dart';
import 'second/kx_second_center.dart';
import 'second/kx_send_btn.dart';

class KXSendSoundMessage extends StatefulWidget {
  /// conversation ID
  final String conversationID;

  /// control the list to bottom
  final VoidCallback onDownBottom;

  /// the conversation type
  final ConvType conversationType;

  final Color? bgColor;

  const KXSendSoundMessage({
    required this.conversationID,
    required this.conversationType,
    Key? key,
    required this.onDownBottom,
    this.bgColor,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _KXSendSoundMessageState();
}

class _KXSendSoundMessageState extends TIMUIKitState<KXSendSoundMessage> {
  final TUIChatGlobalModel model = serviceLocator<TUIChatGlobalModel>();

  bool isRecording = false;
  bool isInit = false;

  DateTime startTime = DateTime.now();
  List<StreamSubscription<Object>> subscriptions = [];

  OverlayEntry? overlayEntry;

  double volume = 0.1;

  //  是否取消

  bool isCancelSend = false;

  // 是否转文字
  bool _isSoundToWord = false;

  // 显示转文字的界面
  bool isShowSoundToWord = false;

  /// 是否正在转化
  bool isConverting = true;

  double btnHeight = 120;
  double bottomHeight = 200;
  double leftAndRight = -20;

  /// 语音转出来的文字
  String _soundToWords = "";

  String? audioPath;

  double? audioLength;

  late final TextEditingController _soundToWordsController =
      TextEditingController();

  late TUIChatSeparateViewModel chatModel;

  buildOverLayView(BuildContext context) {
    if (overlayEntry == null) {
      overlayEntry = OverlayEntry(builder: (content) {
        return Material(
          color: Colors.transparent,
          type: MaterialType.canvas,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Opacity(
                  opacity: 0.8,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(
                      color: Color(0xff77797A),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    child: Center(
                        child: isShowSoundToWord
                            ? KxSecondCenter(
                                editingController: _soundToWordsController,
                                isConverting: isConverting,
                              )
                            : KxFirstCenter(
                                bgColor:
                                    isCancelSend ? Colors.red : Colors.green,
                                content: isCancelSend
                                    ? "松手 取消发送"
                                    : _isSoundToWord
                                        ? "松手 转文字"
                                        : "松手 发送语音",
                              )),
                  ),
                ),
              ),
              if (isShowSoundToWord)
                KxSecondBottomWidget(
                  bottomHeight: bottomHeight,
                  btnHeight: btnHeight,
                  onCancelTap: () {
                    _reSetValue();
                    if (overlayEntry != null) {
                      overlayEntry!.remove();
                      overlayEntry = null;
                    }
                  },
                  onSendSoundTap: () {
                    if (audioPath != null && audioLength != null) {
                      sendSound(
                        path: audioPath!,
                        duration: audioLength!.ceil(),
                        model: chatModel,
                      );
                    }
                    _reSetValue();
                    if (overlayEntry != null) {
                      overlayEntry!.remove();
                      overlayEntry = null;
                    }
                  },
                  onSendWordTap: () {
                    if (audioPath != null && audioLength != null) {
                      sendText(
                          text: _soundToWordsController.text, model: chatModel);

                      if (overlayEntry != null) {
                        overlayEntry!.remove();
                        overlayEntry = null;
                      }
                    }
                    _reSetValue();
                    if (overlayEntry != null) {
                      overlayEntry!.remove();
                      overlayEntry = null;
                    }
                  },
                )
              else ...[
                KxFirstBottomWidget(
                  left: leftAndRight,
                  bottomHeight: bottomHeight,
                  btnHeight: btnHeight,
                  isActive: isCancelSend,
                  angle: -0.2,
                  actionTxt: '取消',
                  actionTip: '松手 取消',
                ),
                KxFirstBottomWidget(
                  right: leftAndRight,
                  bottomHeight: bottomHeight,
                  btnHeight: btnHeight,
                  isActive: _isSoundToWord,
                  actionTxt: '滑到这里 转文字',
                  actionTip: '松手 编辑文字',
                ),
              ]
            ],
          ),
        );
      });
      Overlay.of(context).insert(overlayEntry!);
    }
  }

  onLongPressStart(_) {
    if (isInit) {
      startTime = DateTime.now();
      SoundPlayer.startRecord();
      buildOverLayView(context);
    }
  }

  onLongPressUpdate(e) {
    double dy = e.localPosition.dy;
    double dx = e.localPosition.dx;
    // 我设置的控件距离底部高度
    double minHeight = bottomHeight;
    double maxHeight = bottomHeight + btnHeight;

    // 此处减20 是因为有一个角度倾斜，具体值不是40，需要算，此处忽略
    if (dy.abs() > (minHeight - 40) && dy.abs() < maxHeight) {
      // 20  是左右两边让出来的距离
      // 取消发送
      if (dx.abs() > 0 &&
          dx.abs() <
              (MediaQuery.of(context).size.width / 2 -
                  leftAndRight.abs() -
                  leftAndRight.abs())) {
        if (mounted) {
          setState(() {
            isCancelSend = true;
            _isSoundToWord = false;
          });
        }
      } else if (dx.abs() >
          (MediaQuery.of(context).size.width / 2 - leftAndRight.abs())) {
        if (mounted) {
          setState(() {
            isCancelSend = false;
            _isSoundToWord = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isCancelSend = false;
            _isSoundToWord = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          isCancelSend = false;
          _isSoundToWord = false;
        });
      }
    }
  }

  onLongPressEnd(e) {
    double dy = e.localPosition.dy;
    double dx = e.localPosition.dx;
    // 我设置的控件距离底部高度
    double minHeight = bottomHeight;
    double maxHeight = bottomHeight + btnHeight;

    // 此处减20 是因为有一个角度倾斜，具体值不是40，需要算，此处忽略
    if (dy.abs() > (minHeight - 40) && dy.abs() < maxHeight) {
      // 20  是左右两边让出来的距离
      // 取消发送
      if (dx.abs() > 0 &&
          dx.abs() <
              (MediaQuery.of(context).size.width / 2 -
                  leftAndRight.abs() -
                  leftAndRight.abs())) {
        isCancelSend = true;
      } else if (dx.abs() >
          (MediaQuery.of(context).size.width / 2 - leftAndRight.abs())) {
        _isSoundToWord = true;
      }
    }

    // Did not receive onStop from FlutterPluginRecord if the duration is too short.
    if (DateTime.now().difference(startTime).inSeconds < 1) {
      isCancelSend = true;
      onTIMCallback(TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: TIM_t("说话时间太短"),
          infoCode: 6660404));
    }

    if (isCancelSend) {
      if (overlayEntry != null) {
        overlayEntry!.remove();
        overlayEntry = null;
      }
    } else if (_isSoundToWord) {
      if (mounted) {
        setState(() {
          isShowSoundToWord = true;
          overlayEntry?.markNeedsBuild();
        });
      }
    }

    stop();
  }

  onLonePressCancel() {
    if (isRecording) {
      isCancelSend = true;
      if (overlayEntry != null) {
        overlayEntry!.remove();
        overlayEntry = null;
      }
      stop();
    }
  }

  void stop() {
    setState(() {
      isRecording = false;
    });
    SoundPlayer.stopRecord();
  }

  sendSound({
    required String path,
    required int duration,
    required TUIChatSeparateViewModel model,
  }) {
    final convID = widget.conversationID;
    final convType = widget.conversationType;

    if (duration > 0) {
      if (!isCancelSend) {
        MessageUtils.handleMessageError(
            model.sendSoundMessage(
                soundPath: path,
                duration: duration,
                convID: convID,
                convType: convType),
            context);
        widget.onDownBottom();
      } else {
        isCancelSend = false;
      }
    } else {
      onTIMCallback(TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: TIM_t("说话时间太短"),
          infoCode: 6660404));
    }
  }

  sendText({
    required String text,
    required TUIChatSeparateViewModel model,
  }) {
    final convID = widget.conversationID;
    final convType = widget.conversationType;

    if (text.isNotEmpty) {
      MessageUtils.handleMessageError(
          model.sendTextMessage(text: text, convID: convID, convType: convType),
          context);
      widget.onDownBottom();
    } else {
      onTIMCallback(TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: TIM_t("文本消息为空"),
          infoCode: 6660404));
    }
  }

  @override
  dispose() {
    _soundToWordsController.dispose();
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  initRecordSound(TUIChatSeparateViewModel model) {
    final responseSubscription = SoundPlayer.responseListener((recordResponse) {
      final status = recordResponse.msg;
      if (status == "onStop") {
        if (!isCancelSend) {
          final soundPath = recordResponse.path;
          final recordDuration = recordResponse.audioTimeLength;

          if (_isSoundToWord) {
            _convertSoundToWord(soundPath, recordDuration);
          } else {
            //  是否取消
            _reSetValue();
            if (overlayEntry != null) {
              overlayEntry!.remove();
              overlayEntry = null;
            }

            ///发送语音消息
            sendSound(
                path: soundPath!,
                duration: recordDuration!.ceil(),
                model: model);
          }
        }
      } else if (status == "onStart") {
        outputLogger.i("start record");
        setState(() {
          isRecording = true;
        });
      } else {
        outputLogger.i(status.toString());
      }
    });
    final amplitudesResponseSubscription =
        SoundPlayer.responseFromAmplitudeListener((recordResponse) {
      setState(() {
        volume = double.parse(recordResponse.msg!) * 1.1;
        if (overlayEntry != null) {
          overlayEntry!.markNeedsBuild();
        }
      });
    });
    subscriptions = [responseSubscription, amplitudesResponseSubscription];
    SoundPlayer.initSoundPlayer();
    isInit = true;
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final TUIChatSeparateViewModel model =
        Provider.of<TUIChatSeparateViewModel>(context);
    chatModel = model;
    return GestureDetector(
      onTapDown: (detail) async {
        //////////// 新增：开始录制语音信息是停止播放语音 ////////////
        model.stopAndResetAudio();
        //////////// 新增：开始录制语音信息是停止播放语音 ////////////

        if (!isInit) {
          bool hasMicrophonePermission = await Permissions.checkPermission(
            context,
            Permission.microphone.value,
            theme,
          );
          if (!hasMicrophonePermission) {
            return;
          }
          initRecordSound(model);
        }
      },
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressUpdate,
      onLongPressEnd: onLongPressEnd,
      onLongPressCancel: onLonePressCancel,
      child: Container(
        height: 35,
        color: isRecording
            ? theme.weakBackgroundColor
            : (widget.bgColor ?? Colors.white),
        alignment: Alignment.center,
        child: Text(
          TIM_t("按住说话"),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.darkTextColor,
          ),
        ),
      ),
    );
  }

  // 重置
  void _reSetValue() {
    _soundToWordsController.text = "";
    _soundToWords = "";
    isCancelSend = false;
    _isSoundToWord = false;
    isShowSoundToWord = false;
    isConverting = true;
    audioPath = null;
    audioLength = null;
  }

  /// 语音转文字
  Future<void> _convertSoundToWord(
      String? soundPath, double? recordDuration) async {
    try {
      audioPath = soundPath;
      audioLength = recordDuration;
      File file = File(audioPath!);
      _soundToWords = await model.chatConfig.onVoiceToWordByFile!.call(file);

      if (mounted) {

        setState(() {
          isConverting = false;
          _soundToWordsController.text = _soundToWords;
          overlayEntry?.markNeedsBuild();
        });
      }
    } catch (e) {

      isConverting = false;
      overlayEntry?.markNeedsBuild();
    }
  }
}
