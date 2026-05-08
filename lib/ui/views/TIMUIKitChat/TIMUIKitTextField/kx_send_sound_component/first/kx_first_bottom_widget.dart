import 'package:flutter/material.dart';

class KxFirstBottomWidget extends StatelessWidget {
  KxFirstBottomWidget(
      {super.key,
      this.left,
      this.right,
      required this.bottomHeight,
      required this.btnHeight,
      this.angle = .2,
      required this.isActive,
      required this.actionTxt,
      required this.actionTip});

  double? left;
  double? right;
  final double bottomHeight;
  final double btnHeight;
  final double angle;
  final bool isActive;
  final String actionTxt;
  final String actionTip;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: right,
      left: left,
      bottom: bottomHeight,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          height: btnHeight,
          color: Colors.transparent,
          width: MediaQuery.of(context).size.width / 2,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    isActive ? actionTip : "",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.grey.withValues(alpha: .9),
                    borderRadius: left == null
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            bottomLeft: Radius.circular(40))
                        : const BorderRadius.only(
                            topRight: Radius.circular(40),
                            bottomRight: Radius.circular(40))),
                child: Text(
                  actionTxt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isActive
                          ? Colors.grey.withValues(alpha: .9)
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
