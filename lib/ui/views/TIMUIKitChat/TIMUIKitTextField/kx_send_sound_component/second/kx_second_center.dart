import 'package:flutter/material.dart';

import 'kx_chat_sound_to_word_bubble.dart';

class KxSecondCenter extends StatelessWidget {
  const KxSecondCenter(
      {super.key, required this.editingController, required this.isConverting});

  final TextEditingController editingController;
  final bool isConverting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        KxChatSoundToWordBubble(
          bgColor: Colors.green,
          editingController: editingController,
          isConverting: isConverting,
        ),
        const SizedBox(
          height: 5,
        ),
        Container(
          margin: const EdgeInsets.only(right: 30),
          alignment: Alignment.centerRight,
          child: Text(
            isConverting ? "正在识别文字..." : "点击气泡可编辑文字",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        )
      ],
    );
  }
}
