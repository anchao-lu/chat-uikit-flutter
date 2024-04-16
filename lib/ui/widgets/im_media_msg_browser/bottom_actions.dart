import 'package:flutter/material.dart';

import '../../utils/platform.dart';

class BottomActions extends StatelessWidget {
  const BottomActions({
    super.key,
    this.onDownload,
    this.onPre,
    this.onNext,
  });

  final VoidCallback? onDownload;
  final VoidCallback? onPre;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            if (PlatformUtils().isDesktop) {
              onPre?.call();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.center,
            decoration: const ShapeDecoration(
              color: Colors.black12,
              shape: CircleBorder(),
            ),
            width: 44,
            height: 44,
            child: Icon(
              PlatformUtils().isDesktop ? Icons.arrow_back_ios : Icons.close,
              color: Colors.white,
              size: PlatformUtils().isDesktop ? 40 : 20,
            ),
          ),
        ),
        GestureDetector(
          onTap: PlatformUtils().isDesktop ? onNext : onDownload,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.center,
            decoration: const ShapeDecoration(
              color: Colors.black26,
              shape: CircleBorder(),
            ),
            width: 44,
            height: 44,
            child: Icon(
              PlatformUtils().isDesktop
                  ? Icons.arrow_forward_ios
                  : Icons.arrow_downward_sharp,
              color: Colors.white,
              size: PlatformUtils().isDesktop ? 40 : 20,
            ),
          ),
        ),
      ],
    );
  }
}
