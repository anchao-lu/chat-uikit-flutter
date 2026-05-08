import 'package:flutter/material.dart';

import 'kx_chat_sound_to_word_bubble.dart';

class KxSecondCenter extends StatelessWidget {
  const KxSecondCenter({super.key, required this.editingController});

  final TextEditingController editingController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        KxChatSoundToWordBubble(
          bgColor: Colors.green,
          editingController: editingController,
        ),
        const SizedBox(
          height: 5,
        ),
        Container(
          margin: const EdgeInsets.only(right: 30),
          alignment: Alignment.centerRight,
          child: const Text(
            "点击气泡可编辑文字",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        )
      ],
    );
  }
}
