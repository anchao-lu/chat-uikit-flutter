// ignore_for_file: deprecated_member_use

import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_stateless_widget.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/http_text.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/compiler/md_text.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/DefaultSpecialTextSpanBuilder.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/common/utils.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:tim_ui_kit_sticker_plugin/utils/tim_custom_face_data.dart';

import 'kx_digit_block.dart';

typedef ImageBuilder = Widget Function(
    Uri uri, String? imageDirectory, double? width, double? height);

class LinkTextMarkdown extends TIMStatelessWidget {
  /// Callback for when link is tapped
  final void Function(String)? onLinkTap;

  /// message text
  final String messageText;

  /// text style for default words
  final TextStyle? style;

  final bool? isEnableTextSelection;

  final bool isUseQQPackage;

  final bool isUseTencentCloudChatPackage;

  final bool isUseTencentCloudChatPackageOldKeys;

  final List<CustomEmojiFaceData> customEmojiStickerList;

  const LinkTextMarkdown(
      {Key? key,
      required this.messageText,
      this.isUseQQPackage = false,
      this.isUseTencentCloudChatPackage = false,
      this.isUseTencentCloudChatPackageOldKeys = false,
      this.customEmojiStickerList = const [],
      this.isEnableTextSelection,
      this.onLinkTap,
      this.style})
      : super(key: key);

  @override
  Widget timBuild(BuildContext context) {
    return MarkdownBody(
      data: mdTextCompiler(messageText,
          isUseTencentCloudChatPackage: isUseTencentCloudChatPackage,
          customEmojiStickerList: customEmojiStickerList),
      selectable: isEnableTextSelection ?? false,
      styleSheet: MarkdownStyleSheet.fromTheme(ThemeData(
              textTheme: TextTheme(
                  bodyMedium: style ?? const TextStyle(fontSize: 16.0))))
          .copyWith(
        a: TextStyle(color: LinkUtils.hexToColor("015fff")),
      ),
      extensionSet: md.ExtensionSet.gitHubWeb,
      onTapLink: (
        String link,
        String? href,
        String title,
      ) {
        if (onLinkTap != null) {
          onLinkTap!(href ?? "");
        } else {
          LinkUtils.launchURL(context, href ?? "");
        }
      },
    );
  }
}

class LinkText extends TIMStatelessWidget {
  /// Callback for when link is tapped
  final void Function(String)? onLinkTap;

  /// message text
  final String messageText;

  /// text style for default words
  final TextStyle? style;

  final bool isUseQQPackage;

  final bool isUseTencentCloudChatPackage;

  final bool isUseTencentCloudChatPackageOldKeys;

  final List<CustomEmojiFaceData> customEmojiStickerList;

  final bool? isEnableTextSelection;

  //// 康讯自定义添加方法 start
  final Function(V2TimMessage message, String targetStr)?
      onTextMessageItemClick;

  final V2TimMessage? message;

  //// 康讯自定义添加方法 end

  const LinkText(
      {Key? key,
      required this.messageText,
      this.onLinkTap,
      this.onTextMessageItemClick,
      this.message,
      this.isEnableTextSelection,
      this.style,
      this.isUseQQPackage = false,
      this.isUseTencentCloudChatPackage = false,
      this.isUseTencentCloudChatPackageOldKeys = false,
      this.customEmojiStickerList = const []})
      : super(key: key);

  String _getContentSpan(String text, BuildContext context) {
    List<InlineSpan> _contentList = [];
    String contentData = PlatformUtils().isWeb ? '\u200B' : "";

    Iterable<RegExpMatch> matches = LinkUtils.urlReg.allMatches(text);

    int index = 0;
    for (RegExpMatch match in matches) {
      String c = text.substring(match.start, match.end);
      if (match.start == index) {
        index = match.end;
      }
      if (index < match.start) {
        String a = text.substring(index, match.start);
        index = match.end;
        contentData += a;
        _contentList.add(
          TextSpan(text: a),
        );
      }

      if (LinkUtils.urlReg.hasMatch(c)) {
        contentData += HttpText.flag + c + HttpText.flag;
        _contentList.add(TextSpan(
            text: c,
            style: TextStyle(color: LinkUtils.hexToColor("015fff")),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (onLinkTap != null) {
                  onLinkTap!(text.substring(match.start, match.end));
                } else {
                  LinkUtils.launchURL(
                      context, text.substring(match.start, match.end));
                }
              }));
      } else {
        contentData += c;
        _contentList.add(
          TextSpan(text: c, style: style ?? const TextStyle(fontSize: 16.0)),
        );
      }
    }

    //// 康讯 处理一串文本中包含连续7位数的数字时认为可能是电话号码的改动 start
    /// 此处 7 为自己定义和微信7位数判为疑似电话号码保持一致，考虑到基本不动，在此处写死，需和主项目一致
    ///

    /// 此处需求改动，需要改为可以为不连续的7位数字 start
    List<KxDigitBlock> numMatches = KxDigitBlock.extractDigitBlocks(text);

    /// 此处需求改动，需要改为可以为不连续的7位数字 end

    for (KxDigitBlock match in numMatches) {
      String c = text.substring(match.start, match.end);
      if (match.start == index) {
        index = match.end;
      }
      if (index < match.start) {
        String a = text.substring(index, match.start);
        index = match.end;
        contentData += a;
        _contentList.add(
          TextSpan(text: a),
        );
      }
      if (KxDigitBlock.isValidDigitBlock(c)) {
        contentData += HttpText.flag + c + HttpText.flag;
        _contentList.add(TextSpan(
            text: c,
            style: TextStyle(color: LinkUtils.hexToColor("015fff")),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (message != null) {
                  onTextMessageItemClick?.call(message!, c);
                  // 调用 onTextMessageItemClick 后就不调用 onLinkTap 了
                  return;
                }
              }

        ));
      } else {
        contentData += c;
        _contentList.add(
          TextSpan(text: c, style: style ?? const TextStyle(fontSize: 16.0)),
        );
      }
    }
    //// 康讯 处理一串文本中包含连续7位数的数字时认为可能是电话号码的改动 end

    if (index < text.length) {
      String a = text.substring(index, text.length);
      contentData += a;
      _contentList.add(
        TextSpan(text: a, style: style ?? const TextStyle(fontSize: 16.0)),
      );
    }

    return contentData;
  }

  @override
  Widget timBuild(BuildContext context) {
    return ExtendedText(_getContentSpan(messageText, context), softWrap: true,
        onSpecialTextTap: (dynamic parameter) {
      if (parameter.toString().startsWith(HttpText.flag)) {
        ////// 康讯 处理一串文本中包含连续7位数的数字时认为可能是电话号码的改动 start
        String target = (parameter.toString()).replaceAll(HttpText.flag, '');
        if (target.isNotEmpty) {
          //  判断是纯数字字符串
          // print(isPureInteger('012'));      // true（允许前导零）
          // print(isPureInteger('12.3'));     // false
          // print(isPureInteger('-5'));       // false
          // print(isPureInteger(''));         // false
          if (KxDigitBlock.isValidDigitBlock(target)) {
            if (message != null) {
              onTextMessageItemClick?.call(message!, target);
              // 调用 onTextMessageItemClick 后就不调用 onLinkTap 了
              return;
            }
          }
        }
        ////// 康讯 处理一串文本中包含连续7位数的数字时认为可能是电话号码的改动 end
        if (onLinkTap != null) {
          onLinkTap!((parameter.toString()).replaceAll(HttpText.flag, ''));
        } else {
          LinkUtils.launchURL(
              context, (parameter.toString()).replaceAll(HttpText.flag, ''));
        }
      }
    },
        style: style ?? const TextStyle(fontSize: 16.0),
        specialTextSpanBuilder: DefaultSpecialTextSpanBuilder(
          isUseQQPackage: isUseQQPackage,
          isUseTencentCloudChatPackage: isUseTencentCloudChatPackage,
          isUseTencentCloudChatPackageOldKeys: isUseTencentCloudChatPackageOldKeys,
          customEmojiStickerList: customEmojiStickerList,
          showAtBackground: true,
        ));
  }
}
