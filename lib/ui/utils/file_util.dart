import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileUtil {
  static final FileUtil of = FileUtil._();
  FileUtil._();

  Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      // 创建源文件对象
      final sourceFile = File(sourcePath);

      // 获取目标文件路径的目录
      final destinationDir = Directory(path.dirname(destinationPath));

      // 确保目标目录存在
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      // 复制文件
      await sourceFile.copy(destinationPath);
    } catch (e) {}
  }

////  选择文件夹
  Future<String> selectFolder() async {
    try {
      // 使用 FilePicker 选择文件夹
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        // 用户选择了一个文件夹
        print('选择的文件夹路径: $result');

        return result;
        // 在这里处理选择的文件夹路径
      } else {
        // 用户取消了选择
        print('未选择任何文件夹');
      }
    } catch (e) {
      // 处理错误
      print('选择文件夹时出错: $e');
    }
    return "";
  }
}
