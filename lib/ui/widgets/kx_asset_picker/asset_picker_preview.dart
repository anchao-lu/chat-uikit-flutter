import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/image_edit_util.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/kx_asset_picker/extensions.dart';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'asset_warp_model.dart';
import 'common_app_bar.dart';

class AssetPickerPreview extends StatefulWidget {
  const AssetPickerPreview(
      {super.key, required this.previewAssets, required this.currentIndex});

  final List<AssetEntity> previewAssets;

  /// Current previewing index in assets.
  /// 当前查看的索引
  final int currentIndex;

  @override
  State<AssetPickerPreview> createState() => _AssetPickerPreviewState();
}

class _AssetPickerPreviewState extends State<AssetPickerPreview> {
  int _curIndex = 0;

  /// [PageController] for assets preview [PageView].
  /// 查看图片资源的页面控制器
  PageController get pageController => _pageController;
  late PageController _pageController;

  //// 临时数据
  List<AssetWarpModel> datas = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _curIndex = widget.currentIndex;

    _initDatas();

    _pageController = PageController(
      initialPage: _curIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar.arrowBack(context,
          actions: datas.isEmpty
              ? null
              : [
                  Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor:
                          Colors.white, // Border color for unselected
                    ),
                    child: Radio(
                      toggleable: true,
                      value: datas[_curIndex].selectValue!,
                      activeColor: Colors.green,
                      groupValue: 1,
                      hoverColor: Colors.white,
                      onChanged: (int? value) {
                        if (datas[_curIndex].isSelect) {
                          datas[_curIndex].selectValue = 0;
                        } else {
                          datas[_curIndex].selectValue = 1;
                        }
                        setState(() {});
                      },
                    ),
                  ),
                ],
          backgroundColor: const Color(0xff212121), onBack: () {
        Navigator.of(context).pop(null);
      }),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            color: Colors.black,
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) {
                File? file = datas[index].getShowFile();
                return file == null
                    ? Container()
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: RepaintBoundary(
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
              },
              itemCount: datas.length,
              onPageChanged: (index) {
                setState(() {
                  _curIndex = index;
                });
              },
            ),
          ).expanded(),
          Container(
            height: 180,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  const Color(0xff212121),
                  Colors.black.withOpacity(.9),
                  Colors.black,
                ])),
            child: Column(
              children: [
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      File? file = datas[index].getShowFile();
                      return GestureDetector(
                        onTap: () {
                          _onBottomTap(index);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 2),
                          child: Container(
                            decoration: BoxDecoration(
                              border: index == _curIndex
                                  ? Border.all(color: Colors.green, width: 2)
                                  : null,
                            ),
                            child: file == null
                                ? Container()
                                : Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                  ),
                            height: 80,
                            width: 80,
                          ),
                        ),
                      );
                    },
                    itemCount: datas.length,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final file = await datas[_curIndex].assetEntity!.file;
                        if (file != null) {
                          ImageEditUtil.of.openEdit(
                              context: context,
                              file: file,
                              entity: datas[_curIndex].assetEntity!,
                              tempPathCallBack: (tempPath) {
                                datas[_curIndex].newPath = tempPath;
                                setState(() {});
                              });
                        }
                      },
                      child: const Text("编辑",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          )),
                    ),
                    GestureDetector(
                      onTap: () {
                        List<AssetEntity> copys = _selectedList.map((value) {
                          return value.assetEntity!
                              .copyWith(relativePath: value.newPath);
                        }).toList();

                        Navigator.of(context).pop(copys);
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        height: 32,
                        width: 80,
                        alignment: Alignment.center,
                        child: Text(
                          "发送(${_getCount()})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ).expanded()
              ],
            ),
          )
        ],
      ),
    );
  }

  List<AssetWarpModel> get _selectedList => datas.where((value) {
        return value.isSelect;
      }).toList();

  String _getCount() {
    return "${_selectedList.length}";
  }

  Widget appBar() {
    return const Row(
      children: [
        Icon(
          Icons.close,
          size: 18.0,
        ),
      ],
    );
  }

  void _onBottomTap(int index) {
    setState(() {
      _curIndex = index;
    });
    _pageController.jumpToPage(_curIndex);
  }

  Future<void> _initDatas() async {
    datas.clear();
    datas.addAll(await AssetWarpModel.transFor(widget.previewAssets));
    setState(() {});
  }
}
