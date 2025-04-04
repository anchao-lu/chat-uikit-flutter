import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'asset_picker_preview.dart';
import 'kx_asset_picker_viewer_builder_delegate.dart';

class KxAssetPickerBuilderDelegate extends DefaultAssetPickerBuilderDelegate {
  KxAssetPickerBuilderDelegate({
    required super.provider,
    required super.initialPermission,
    super.gridCount,
    super.pickerTheme,
    super.specialItemPosition,
    super.specialItemBuilder,
    super.loadingIndicatorBuilder,
    super.selectPredicate,
    super.shouldRevertGrid,
    super.limitedPermissionOverlayPredicate,
    super.pathNameBuilder,
    super.themeColor,
    super.textDelegate,
    super.locale,
    super.gridThumbnailSize = defaultAssetGridPreviewSize,
    super.previewThumbnailSize,
    super.specialPickerType,
    super.keepScrollOffset = false,
  });
  
  @override
  Future<void> viewAsset(
    BuildContext context,
    int index,
    AssetEntity currentAsset,
  ) async {
    final DefaultAssetPickerProvider provider =
        context.read<DefaultAssetPickerProvider>();
    // final List<AssetEntity>? result =
    //     await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
    //   return  AssetPickerPreview(
    //     previewAssets: provider.selectedAssets,
    //     currentIndex: 0,
    //   );
    // }));

    // Navigator.of(context).maybePop(result);

    //   // - When we reached the maximum select count and the asset is not selected,
    //   //   do nothing.
    //   // - When the special type is WeChat Moment, pictures and videos cannot
    //   //   be selected at the same time. Video select should be banned if any
    //   //   pictures are selected.
    if ((!provider.selectedAssets.contains(currentAsset) &&
            provider.selectedMaximumAssets) ||
        (isWeChatMoment &&
            currentAsset.type == AssetType.video &&
            provider.selectedAssets.isNotEmpty)) {
      return;
    }
    final List<AssetEntity> current;
    final List<AssetEntity>? selected;
    final int effectiveIndex;
    if (isWeChatMoment) {
      if (currentAsset.type == AssetType.video) {
        current = <AssetEntity>[currentAsset];
        selected = null;
        effectiveIndex = 0;
      } else {
        current = provider.currentAssets
            .where((AssetEntity e) => e.type == AssetType.image)
            .toList();
        selected = provider.selectedAssets;
        effectiveIndex = current.indexOf(currentAsset);
      }
    } else {
      current = provider.currentAssets;
      selected = provider.selectedAssets;
      effectiveIndex = index;
    }
    // final List<AssetEntity>? result = await AssetPickerViewer.pushToViewer(
    //   context,
    //   currentIndex: effectiveIndex,
    //   previewAssets: current,
    //   themeData: theme,
    //   previewThumbnailSize: previewThumbnailSize,
    //   selectPredicate: selectPredicate,
    //   selectedAssets: selected,
    //   selectorProvider: provider,
    //   specialPickerType: specialPickerType,
    //   maxAssets: provider.maxAssets,
    //   shouldReversePreview: isAppleOS(context),
    // );

    final AssetPickerViewerBuilderDelegate<AssetEntity, AssetPathEntity>
        viewerDelegate = KxAssetPickerViewerBuilderDelegate(
      currentIndex: effectiveIndex,
      previewAssets: current,
      provider: selected != null
          ? AssetPickerViewerProvider<AssetEntity>(
              selected,
              maxAssets: provider.maxAssets,
            )
          : null,
      themeData: theme,
      previewThumbnailSize: previewThumbnailSize,
      specialPickerType: specialPickerType,
      selectedAssets: selected,
      selectorProvider: provider,
      maxAssets: provider.maxAssets,
      shouldReversePreview: isAppleOS(context),
      selectPredicate: selectPredicate,
    );

    final List<AssetEntity>? result =
        await AssetPickerViewer.pushToViewerWithDelegate(
      context,
      delegate: viewerDelegate,
    );

    if (result != null) {
      Navigator.of(context).maybePop(result);
    }
  }
}