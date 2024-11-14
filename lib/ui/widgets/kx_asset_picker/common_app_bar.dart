import 'package:flutter/material.dart';

class CommonAppBar {
  static AppBar arrowBack(
    BuildContext context, {
    String title = '',
    VoidCallback? onBack,
    List<Widget>? actions,
    double? elevation,
    bool? centerTitle,
    bool hideArrow = false,
    Widget? flexibleSpace,
    Color? backgroundColor,
    Color? arrowColor,
    Color? titleColor,
    Widget? cusTitle,
    Widget? cusLeading,
  }) =>
      AppBar(
        backgroundColor: backgroundColor,
        title: cusTitle,
        elevation: elevation ?? 0.0,
        centerTitle: centerTitle ?? true,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: cusLeading ??
            (hideArrow
                ? null
                : InkWell(
                    onTap: onBack,
                    child: Icon(Icons.arrow_back_ios),
                  )),
        actions: actions,
        flexibleSpace: flexibleSpace,
      );
}
