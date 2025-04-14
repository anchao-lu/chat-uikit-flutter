import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart' as proImg;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'file_util.dart';

class ImageEditUtil {
  static final ImageEditUtil of = ImageEditUtil._();

  ImageEditUtil._();

  void openEdit(
      {required BuildContext context,
      required File file,
      required AssetEntity entity,
      required ValueChanged<String> tempPathCallBack}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => proImg.ProImageEditor.file(
          file,
          callbacks: proImg.ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              /*
              Your code to handle the edited image. Upload it to your server as an example.
              You can choose to use await, so that the loading-dialog remains visible until your code is ready, or no async, so that the loading-dialog closes immediately.
              By default, the bytes are in `jpg` format.
            */

              try {
                String? tempPath = (await getTemporaryDirectory()).path;

                /////  start 首先 删除缓存文件
                ///
                // 检查目录是否存在
                final directory = Directory(tempPath);
                if (await directory.exists()) {
                  // 列出所有文件
                  List<FileSystemEntity> files = directory.listSync();

                  for (var file in files) {
                    if (file is File) {
                      final filepath = file.path;
                      if (filepath.contains("kx_image_edit_")) {
                        // 是缓存文件
                        await FileUtil.of.deleteFile(filepath);
                        print("删除文件$filepath");
                      }
                    }
                  }
                }

                ///end 删除缓存文件
                String fileName =
                    "$tempPath/kx_image_edit_${_getTempTitle(entity: entity)}${_getType(entity: entity)}";
                // 创建文件路径
                File file = File(fileName);
                // 写入数据到文件
                await file.writeAsBytes(bytes);
                // 返回文件路径
                tempPathCallBack.call(file.path);
              } catch (e) {}

              Navigator.pop(context);
            },
          ),
          configs: const proImg.ProImageEditorConfigs(
            i18n: proImg.I18n(
              various: proImg.I18nVarious(
                  loadingDialogMsg: "请稍等...",
                  closeEditorWarningTitle: "关闭图片编辑?",
                  closeEditorWarningMessage: "退出图片编辑，所做的更改将不会被保存",
                  closeEditorWarningCancelBtn: "取消",
                  closeEditorWarningConfirmBtn: "确认"),
              blurEditor: proImg.I18nBlurEditor(
                bottomNavigationBarText: "模糊",
              ),
              filterEditor:
                  proImg.I18nFilterEditor(bottomNavigationBarText: "滤镜"),
              emojiEditor:
                  proImg.I18nEmojiEditor(bottomNavigationBarText: "表情"),
              paintEditor: proImg.I18nPaintingEditor(
                moveAndZoom: '缩放',
                bottomNavigationBarText: '绘画',
                freestyle: '自由',
                arrow: '箭头',
                line: '线',
                rectangle: '矩形',
                circle: '圆',
                dashLine: '虚线',
                lineWidth: '线宽',
                eraser: '橡皮',
                toggleFill: 'Toggle fill',
                changeOpacity: '透明度',
                undo: '撤回',
                redo: '重做',
                done: '完成',
                back: '返回',
                smallScreenMoreTooltip: '更多',
              ),
              textEditor: proImg.I18nTextEditor(
                inputHintText: '输入文字',
                bottomNavigationBarText: '文字',
                back: '返回',
                done: '完成',
                textAlign: '字体对齐',
                fontScale: '字体缩放',
                backgroundMode: '背景模式',
                smallScreenMoreTooltip: '更多',
              ),

              cropRotateEditor: proImg.I18nCropRotateEditor(
                bottomNavigationBarText: '裁剪/旋转',
                rotate: '旋转',
                flip: '翻转',
                ratio: '比例',
                back: '返回',
                done: '完成',
                cancel: '取消',
                undo: '撤回',
                redo: '重做',
                smallScreenMoreTooltip: '更多',
                reset: '重置',
              ),
              stickerEditor: proImg.I18nStickerEditor(),
              // More translations...
              importStateHistoryMsg: '初始化编辑器',
              cancel: '取消',
              undo: '撤回',
              redo: '重做',
              done: '完成',
              remove: '移除',
              doneLoadingMsg: '正在保存更改...',
            ),
          ),
        ),
      ),
    );
  }

  String _getTempTitle({required AssetEntity entity}) {
    String title = "";
    if (entity.title != null && entity.title!.isNotEmpty) {
      title = entity.title!.split(".")[0];
    }
    return "${entity.id}_${entity.createDateSecond ?? ""}_$title";
  }

  /// Get image type by reading the file extension.
  /// 从图片后缀判断图片类型
  ///
  /// ⚠ Not all the system version support read file name from the entity,
  /// so this method might not work sometime.
  /// 并非所有的系统版本都支持读取文件名，所以该方法有时无法返回正确的类型。
  String _getType({
    required AssetEntity entity,
  }) {
    final String? extension =
        entity.mimeType?.split('/').last ?? entity.title?.split('.').last;
    if (extension != null) {
      switch (extension.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
          return ".jpg";
        case 'png':
          return ".png";
        case 'gif':
          return ".gif";

        case 'tiff':
          return ".tiff";

        case 'heic':
          return ".heic";

        default:
          return ".png";
      }
    }
    return ".png";
  }
}
