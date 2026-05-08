

import 'package:flutter/material.dart';

class KxIconWidget extends StatelessWidget {
  KxIconWidget(
      {super.key,
      this.size = 70,
      required this.icon,
      required this.content,
      required this.bgColor,
      required this.onTap});

  double size;
  final IconData icon;
  final String content;
  final Color bgColor;

  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap.call();
      },
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            width: size,
            height: size,
            decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }
}
