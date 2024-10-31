import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:flutter/physics.dart' as physics show SpringDescription;

class KxAssetPickerViewerBuilderDelegate
    extends DefaultAssetPickerViewerBuilderDelegate {
  KxAssetPickerViewerBuilderDelegate({
    required super.currentIndex,
    required super.previewAssets,
    required super.themeData,
    super.selectorProvider,
    super.provider,
    super.selectedAssets,
    super.previewThumbnailSize,
    super.specialPickerType,
    super.maxAssets,
    super.shouldReversePreview,
    super.selectPredicate,
  });

  Widget _pageViewBuilder(BuildContext context) {
    return Semantics(
      sortKey: ordinalSortKey(1),
      child: ExtendedImageGesturePageView.builder(
        physics: previewAssets.length == 1
            ? const _CustomClampingScrollPhysics()
            : const _CustomBouncingScrollPhysics(),
        controller: pageController,
        itemCount: previewAssets.length,
        itemBuilder: assetPageBuilder,
        reverse: shouldReversePreview,
        onPageChanged: (int index) {
          currentIndex = index;
          pageStreamController.add(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeData,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: themeData.appBarTheme.systemOverlayStyle ??
            (themeData.effectiveBrightness.isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark),
        child: Material(
          color: themeData.colorScheme.onSecondary,
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: _pageViewBuilder(context)),
              if (isWeChatMoment && hasVideo) ...<Widget>[
                momentVideoBackButton(context),
                PositionedDirectional(
                  end: 16,
                  bottom: context.bottomPadding + 16,
                  child: confirmButton(context),
                ),
              ] else ...<Widget>[
                appBar(context),
                if (selectedAssets != null ||
                    (isWeChatMoment && hasVideo && isAppleOS(context)))
                  bottomDetailBuilder(context),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomClampingScrollPhysics extends ClampingScrollPhysics {
  const _CustomClampingScrollPhysics({
    super.parent,
  });

  @override
  _CustomClampingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _CustomClampingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  physics.SpringDescription get spring {
    return physics.SpringDescription.withDampingRatio(
      mass: 0.5,
      stiffness: 400.0,
      ratio: 1.1,
    );
  }
}

class _CustomBouncingScrollPhysics extends BouncingScrollPhysics {
  const _CustomBouncingScrollPhysics({
    super.parent,
  });

  @override
  _CustomBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _CustomBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  physics.SpringDescription get spring {
    return physics.SpringDescription.withDampingRatio(
      mass: 0.5,
      stiffness: 400.0,
      ratio: 1.1,
    );
  }
}


extension _ThemeDataExtension on ThemeData {
  Brightness get effectiveBrightness =>
      appBarTheme.systemOverlayStyle?.statusBarBrightness ?? brightness;
}

extension _BrightnessExtension on Brightness {
  bool get isDark => this == Brightness.dark;
}

extension _BuildContextExtension on BuildContext {
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
}
