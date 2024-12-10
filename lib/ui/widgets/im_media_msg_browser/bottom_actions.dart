import 'package:flutter/material.dart';

import '../../utils/platform.dart';

class BottomActions extends StatelessWidget {
  const BottomActions({
    super.key,
    this.onDownload,
    this.onPre,
    this.onNext,
    this.onView,
    this.onMore,
    this.showMenu = true,
  });

  final VoidCallback? onDownload;
  final VoidCallback? onPre;
  final VoidCallback? onNext;
  final VoidCallback? onView;
  final VoidCallback? onMore;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: PlatformUtils().isDesktop
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      children: PlatformUtils().isDesktop
          ? [
              BottomItem(
                  onTap: () {
                    onPre?.call();
                  },
                  iconWidget: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 40,
                  )),
              BottomItem(
                onTap: onNext,
                iconWidget: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ]
          : [
              BottomItem(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  iconWidget: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  )),
              BottomItem(
                onTap: onDownload,
                iconWidget: const Icon(
                  Icons.arrow_downward_sharp,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (showMenu)
                BottomItem(
                  onTap: onView,
                  iconWidget: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              BottomItem(
                onTap: onMore,
                iconWidget: const Icon(
                  Icons.more_horiz_sharp,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
    );
  }
}

class BottomItem extends StatelessWidget {
  const BottomItem({
    super.key,
    this.onTap,
    required this.iconWidget,
    this.size = 44,
  });

  final VoidCallback? onTap;

  final Widget iconWidget;

  final double size;


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
      },
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: PlatformUtils().isDesktop ? 15 : 5),
        alignment: Alignment.center,
        decoration: const ShapeDecoration(
          color: Colors.black26,
          shape: CircleBorder(),
        ),
        width: 44,
        height: 44,
        child: iconWidget,
      ),
    );
  }
}
