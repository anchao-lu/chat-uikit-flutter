import 'package:flutter/material.dart';

class KxSendBtn extends StatelessWidget {
  const KxSendBtn({super.key, required this.onTap});

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
              width: 140,
              height: 60,
              decoration: BoxDecoration(
                  color: Colors.white70.withValues(alpha: .9),
                  borderRadius: const BorderRadius.all(Radius.circular(30))),
              child:  Text(
                "发送",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: .8),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ));
  }
}
