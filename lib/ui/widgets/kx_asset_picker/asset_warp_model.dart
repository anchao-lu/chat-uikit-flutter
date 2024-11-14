import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetWarpModel {
  AssetWarpModel(
      {this.assetEntity,
      this.selectValue,
      this.color,
      this.newPath,
      this.originFile});

  AssetEntity? assetEntity;

  // 1 代表选中
  int? selectValue;
  Color? color;

  String? newPath;

  File? originFile;

  bool get isSelect => selectValue == 1;

  static Future<List<AssetWarpModel>> transFor(List<AssetEntity>? list) async {
    if (list == null || list.isEmpty) return [];

    List<AssetWarpModel> temps = [];

    for (var data in list) {
      File? tempFile = await data.file;
      AssetWarpModel model = AssetWarpModel(
          assetEntity: data,
          selectValue: 1,
          color: Colors.black,
          originFile: tempFile);

      temps.add(model);
    }

    return temps;
  }

  /// 获取展示文件
  File? getShowFile() {
    if (newPath == null || newPath!.isEmpty) {
      return originFile;
    }

    return File(newPath!);
  }
}
