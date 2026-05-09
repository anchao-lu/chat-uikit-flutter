class KxDigitBlock {
  final String text;
  final int start;
  final int end; // 不包含该索引，即 [start, end)

  KxDigitBlock(this.text, this.start, this.end);

  @override
  String toString() => '[$start, $end): "$text"';

  static List<KxDigitBlock> extractDigitBlocks(String input,
      {int minDigits = 7}) {
    final blocks = <KxDigitBlock>[];
    int? blockStart;
    final buffer = StringBuffer();
    bool inBlock = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final isDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
      final isSpace = char == ' ';

      if (isDigit) {
        if (!inBlock) {
          blockStart = i; // 标记块起始索引
          inBlock = true;
        }
        buffer.write(char);
      } else if (isSpace && inBlock) {
        buffer.write(char);
      } else {
        // 遇到非数字、非空格字符，结束当前块
        if (inBlock) {
          final blockText = buffer.toString();
          final digitCount = blockText
              .replaceAll(' ', '')
              .length;
          if (digitCount >= minDigits) {
            blocks.add(KxDigitBlock(blockText, blockStart!, i));
          }
          buffer.clear();
          inBlock = false;
          blockStart = null;
        }
      }
    }
    // 处理末尾可能遗留的块
    if (inBlock) {
      final blockText = buffer.toString();
      final digitCount = blockText
          .replaceAll(' ', '')
          .length;
      if (digitCount >= minDigits) {
        blocks.add(KxDigitBlock(blockText, blockStart!, input.length));
      }
    }
    return blocks;
  }


  // 测试

  static bool isValidDigitBlock(String str, {int minDigits = 7}) {
    if (str.isEmpty) return false;
    List<KxDigitBlock> temps = extractDigitBlocks(str);

    return temps.isNotEmpty;
  }

}
