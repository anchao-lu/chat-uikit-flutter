import 'dart:convert';

import 'package:flutter/cupertino.dart';

typedef LinkPreviewText = Widget Function({TextStyle? style});

class LocalCustomDataModel {
  final String? description;
  final String? image;
  final String? url;
  final String? title;
  String? translatedText;

  ////////////// 自定义 //////////////
  String? convertVoiceToText;
  ////////////// 自定义 //////////////

  LocalCustomDataModel({
    this.description,
    this.image,
    this.url,
    this.title,
    this.translatedText,
    ////////////// 自定义 //////////////
    this.convertVoiceToText,
    ////////////// 自定义 //////////////
  });

  Map<String, String?> toMap() {
    final Map<String, String?> data = {};
    data['url'] = url;
    data['image'] = image;
    data['title'] = title;
    data['description'] = description;
    data['translatedText'] = translatedText;
    ////////////// 自定义 //////////////
    data['convertVoiceToText'] = convertVoiceToText;
    ////////////// 自定义 //////////////
    return data;
  }

  LocalCustomDataModel.fromMap(Map map)
      : description = map['description'],
        image = map['image'],
        url = map['url'],
        translatedText = map['translatedText'],
        ////////////// 自定义 //////////////
        convertVoiceToText = map['convertVoiceToText'],
        ///////////////// 自定义 ///////////
        title = map['title'];

  @override
  String toString() {
    return json.encode(toMap());
  }

  bool isLinkPreviewEmpty() {
    if ((image == null || image!.isEmpty) &&
        (title == null || title!.isEmpty) &&
        (description == null || description!.isEmpty)) {
      return true;
    }
    return false;
  }
}

class LinkPreviewContent {
  const LinkPreviewContent({
    this.linkInfo,
    this.linkPreviewWidget,
  });

  final LocalCustomDataModel? linkInfo;
  final Widget? linkPreviewWidget;
}
