import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hbb/aproxia_brand.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:window_manager/window_manager.dart';

class InstallPage extends StatefulWidget {
  const InstallPage({Key? key}) : super(key: key);

  @override
  State<InstallPage> createState() => _InstallPageState();
}

class _InstallPageState extends State<InstallPage> {
  final tabController = DesktopTabController(tabType: DesktopTabType.main);

  _InstallPageState() {
    Get.put<DesktopTabController>(tabController);
    const label = 'Instalare Aproxia';
    tabController.add(TabInfo(
      key: label,
      label: label,
      closable: false,
      page: _InstallPageBody(key: const ValueKey(label)),
    ));
  }

  @override
  void dispose() {
    super.dispose();
    Get.delete<DesktopTabController>();
  }

  @override
  Widget build(BuildContext context) {
    return DragToResizeArea(
      resizeEdgeSize: stateGlobal.resizeEdgeSize.value,
      enableResizeEdges: windowManagerEnableResizeEdges,
      child: Scaffold(
        backgroundColor: AproxiaBrand.canvas,
        body: DesktopTab(controller: tabController, showLogo: false),
      ),
    );
  }
}

class _InstallPageBody extends StatefulWidget {
  const _InstallPageBody({Key? key}) : super(key: key);

  @override
  State<_InstallPageBody> createState() => _InstallPageBodyState();
}

class _InstallPageBodyState extends State<_InstallPageBody> with WindowListener {
  late final TextEditingController controller;
  final RxBool startmenu = true.obs;
  final RxBool desktopicon = true.obs;
  final RxBool printer = false.obs;
  final RxBool showProgress = false.obs;
  final RxBool btnEnabled = true.obs;

  final buttonStyle = OutlinedButton.styleFrom(
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  _InstallPageBodyState() {
    controller = TextEditingController(text: bind.installInstallPath());
    final installOptions = jsonDecode(bind.installInstallOptions());
    startmenu.value = installOptions['STARTMENUSHORTCUTS'] != '0';
    desktopicon.value = installOptions['DESKTOPSHORTCUTS'] != '0';
    printer.value = installOptions['PRINTER'] == '1';
  }

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    gFFI.close();
    super.onWindowClose();
    windowManager.setPreventClose(false);
    windowManager.close();
  }

  Widget option(RxBool value, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => btnEnabled.value ? value.value = !value.value : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Obx(() => Checkbox(
                  value: value.value,
                  onChanged: (_) => btnEnabled.value ? value.value = !value.value : null,
                )),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: AproxiaBrand.text))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AproxiaBrand.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AproxiaBrand.border),
                boxShadow: [BoxShadow(color: AproxiaBrand.ink.withOpacity(.06), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      AproxiaMark(size: 52),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Instalează Aproxia', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: AproxiaBrand.text)),
                            SizedBox(height: 4),
                            Text('Instalarea permite acces complet la distanță, inclusiv prin ferestrele Windows UAC.', style: TextStyle(fontSize: 13, color: AproxiaBrand.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text('Locația instalării', style: TextStyle(fontWeight: FontWeight.w700, color: AproxiaBrand.text)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          readOnly: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FBFF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AproxiaBrand.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AproxiaBrand.border)),
                          ),
                        ).workaroundFreezeLinuxMint(),
                      ),
                      const SizedBox(width: 10),
                      Obx(() => OutlinedButton.icon(
                            icon: const Icon(Icons.folder_outlined, size: 18),
                            onPressed: btnEnabled.value ? selectInstallPath : null,
                            style: buttonStyle,
                            label: const Text('Schimbă'),
                          )),
                    ],
                  ),
                  const SizedBox(height: 18),
                  option(startmenu, 'Creează scurtătură în meniul Start'),
                  option(desktopicon, 'Creează scurtătură pe desktop'),
                  option(printer, 'Instalează imprimanta virtuală Aproxia'),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD5E7FB)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: AproxiaBrand.accent, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Prin instalare confirmi că dorești să rulezi Aproxia ca serviciu de sistem. Componentele open-source și licențele aferente rămân disponibile în pachetul și repository-ul proiectului.',
                            style: TextStyle(fontSize: 12, height: 1.4, color: AproxiaBrand.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => showProgress.value ? const LinearProgressIndicator() : const SizedBox.shrink()),
                      ),
                      const SizedBox(width: 14),
                      Obx(() => OutlinedButton.icon(
                            icon: const Icon(Icons.close_rounded, size: 17),
                            label: const Text('Anulează'),
                            onPressed: btnEnabled.value ? () => windowManager.close() : null,
                            style: buttonStyle,
                          )),
                      const SizedBox(width: 10),
                      Obx(() => ElevatedButton.icon(
                            icon: const Icon(Icons.download_done_rounded, size: 17),
                            label: const Text('Instalează Aproxia'),
                            onPressed: btnEnabled.value ? install : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AproxiaBrand.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          )),
                      Offstage(
                        offstage: bind.installShowRunWithoutInstall(),
                        child: Obx(() => OutlinedButton.icon(
                              icon: const Icon(Icons.screen_share_outlined, size: 17),
                              label: const Text('Rulează fără instalare'),
                              onPressed: btnEnabled.value ? () => bind.installRunWithoutInstall() : null,
                              style: buttonStyle,
                            ).marginOnly(left: 10)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void install() {
    btnEnabled.value = false;
    showProgress.value = true;
    String args = '';
    if (startmenu.value) args += ' startmenu';
    if (desktopicon.value) args += ' desktopicon';
    if (printer.value) args += ' printer';
    bind.installInstallMe(options: args, path: controller.text);
  }

  void selectInstallPath() async {
    final installPath = await FilePicker.platform.getDirectoryPath(initialDirectory: controller.text);
    if (installPath != null) {
      controller.text = join(installPath, await bind.mainGetAppName());
    }
  }
}
