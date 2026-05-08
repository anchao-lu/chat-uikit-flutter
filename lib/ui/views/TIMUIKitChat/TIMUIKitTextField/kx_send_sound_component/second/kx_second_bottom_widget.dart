import 'package:flutter/material.dart';

import 'kx_icon_widget.dart';
import 'kx_send_btn.dart';

class KxSecondBottomWidget extends StatelessWidget {
  const KxSecondBottomWidget(
      {super.key,
      required this.bottomHeight,
      required this.btnHeight,
      required this.onCancelTap,
      required this.onSendSoundTap,
      required this.onSendWordTap});

  final double bottomHeight;
  final double btnHeight;

  final Function onCancelTap;
  final Function onSendSoundTap;
  final Function onSendWordTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: bottomHeight - 80,
      child: Container(
        height: btnHeight,
        color: Colors.transparent,
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            KxIconWidget(
                icon: Icons.close,
                content: '取消',
                bgColor: Colors.red,
                onTap: () {
                  onCancelTap.call();
                }),
            KxIconWidget(
                bgColor: Colors.green,
                icon: Icons.multitrack_audio_sharp,
                content: '发送原语音',
                onTap: () {
                  onSendSoundTap.call();
                }),
            KxSendBtn(
              onTap: () {
                onSendWordTap.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
