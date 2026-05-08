import 'package:flutter/material.dart';

import '../bases/kx_bar_visualizer.dart';

/// 最简单的聊天气泡组件（仅文本，尖角朝正下方）
class KxFirstCenter extends StatelessWidget {
  const KxFirstCenter({
    super.key,
    required this.bgColor,
    required this.content,
  });

  final Color bgColor;
  final String content;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _BottomTailBubbleClipper(),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 35),
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KxBarVisualizer(
              isRecording: true,
              amplitude: 0.5,
              color: Colors.white,
              height: 30.0,
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              content,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}

/// 自定义剪裁：圆角矩形 + 底部中心尖角（正下方）
class _BottomTailBubbleClipper extends CustomClipper<Path> {
  const _BottomTailBubbleClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 16.0;
    const tailHeight = 12.0;
    const tailHalfWidth = 8.0;

    // 矩形（预留尖角高度）
    final rect = Rect.fromLTWH(0, 0, size.width, size.height - tailHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));
    path.addRRect(rrect);

    // 底部尖角
    final centerX = size.width / 2;
    final bottomY = size.height - tailHeight;
    path.moveTo(centerX - tailHalfWidth, bottomY);
    path.lineTo(centerX, bottomY + tailHeight);
    path.lineTo(centerX + tailHalfWidth, bottomY);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
