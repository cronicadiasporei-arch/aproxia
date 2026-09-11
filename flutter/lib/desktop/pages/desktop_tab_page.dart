import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/desktop_home_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import '../../common/shared_state.dart';

class DesktopTabPage extends StatefulWidget {
  const DesktopTabPage({Key? key}) : super(key: key);

  @override
  State<DesktopTabPage> createState() => _DesktopTabPageState();

  static void onAddSetting({SettingsTabKey initialPage = SettingsTabKey.general}) {
    try {
      final DesktopTabController tabController = Get.find<DesktopTabController>();
      tabController.add(TabInfo(
        key: kTabLabelSettingPage,
        label: 'Setări',
        selectedIcon: Icons.tune_rounded,
        unselectedIcon: Icons.tune_outlined,
        page: DesktopSettingPage(
          key: const ValueKey(kTabLabelSettingPage),
          initialTabkey: initialPage,
        ),
      ));
    } catch (e) {
      debugPrintStack(label: '$e');
    }
  }
}

class _DesktopTabPageState extends State<DesktopTabPage> {
  final tabController = DesktopTabController(tabType: DesktopTabType.main);

  _DesktopTabPageState() {
    RemoteCountState.init();
    Get.put<DesktopTabController>(tabController);
    tabController.add(TabInfo(
      key: kTabLabelHomePage,
      label: 'Acasă',
      selectedIcon: Icons.home_rounded,
      unselectedIcon: Icons.home_outlined,
      closable: false,
      page: DesktopHomePage(key: const ValueKey(kTabLabelHomePage)),
    ));

    if (bind.isIncomingOnly()) {
      tabController.onSelected = (key) {
        if (key == kTabLabelHomePage) {
          windowManager.setSize(getIncomingOnlyHomeSize());
          setResizable(false);
        } else {
          windowManager.setSize(getIncomingOnlySettingsSize());
          setResizable(true);
        }
      };
    }
  }

  @override
  void dispose() {
    Get.delete<DesktopTabController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabWidget = Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: DesktopTab(
        controller: tabController,
        showLogo: false,
        tail: Offstage(
          offstage: bind.isIncomingOnly() || bind.isDisableSettings(),
          child: ActionIcon(
            message: 'Setări',
            icon: IconFont.menu,
            onTap: DesktopTabPage.onAddSetting,
            isClose: false,
          ),
        ),
      ),
    );

    return isMacOS || kUseCompatibleUiMode
        ? tabWidget
        : Obx(
            () => DragToResizeArea(
              resizeEdgeSize: stateGlobal.resizeEdgeSize.value,
              enableResizeEdges: windowManagerEnableResizeEdges,
              child: tabWidget,
            ),
          );
  }
}
