import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/aproxia_brand.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/animated_rotation_widget.dart';
import 'package:flutter_hbb/common/widgets/custom_password.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/desktop/widgets/update_progress.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:flutter_hbb/utils/platform_channel.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart' as window_size;
import '../widgets/button.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({Key? key}) : super(key: key);
  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

const borderColor = Color(0xFF2F65BA);

class _DesktopHomePageState extends State<DesktopHomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _leftPaneScrollController = ScrollController();
  @override
  bool get wantKeepAlive => true;
  var systemError = '';
  StreamSubscription? _uniLinksSubscription;
  var svcStopped = false.obs;
  var watchIsCanScreenRecording = false;
  var watchIsProcessTrust = false;
  var watchIsInputMonitoring = false;
  var watchIsCanRecordAudio = false;
  Timer? _updateTimer;
  bool isCardClosed = false;
  final RxBool _editHover = false.obs;
  final RxBool _block = false.obs;
  final GlobalKey _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final incoming = bind.isIncomingOnly();
    return _buildBlock(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      buildLeftPane(context),
      if (!incoming) Expanded(child: buildRightPane(context)),
    ]));
  }

  Widget _buildBlock({required Widget child}) => buildRemoteBlock(block: _block, mask: true, use: canBeBlocked, child: child);

  Widget buildLeftPane(BuildContext context) {
    final incoming = bind.isIncomingOnly();
    final outgoing = bind.isOutgoingOnly();
    final children = <Widget>[
      if (!outgoing) buildPresetPasswordWarning(),
      _buildAproxiaBrand(),
      if (!outgoing) buildIDBoard(context),
      if (!outgoing) buildPasswordBoard(context),
      if (!outgoing) _buildLocalActions(),
      FutureBuilder<Widget>(
        future: Future.value(Obx(() => buildHelpCards(stateGlobal.updateUrl.value))),
        builder: (_, data) {
          if (data.hasData) {
            if (incoming && isInHomePage()) Future.delayed(const Duration(milliseconds: 300), _updateWindowSize);
            return data.data!;
          }
          return const Offstage();
        },
      ),
    ];
    if (incoming) {
      children.addAll([const Divider(), OnlineStatusWidget(onSvcStatusChanged: () {
        if (isInHomePage()) Future.delayed(const Duration(milliseconds: 300), _updateWindowSize);
      }).marginOnly(bottom: 6, right: 6)]);
    }
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Container(
        width: incoming ? 300 : 286,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B2D55), Color(0xFF071C38)]),
        ),
        child: Stack(children: [
          Column(children: [
            Expanded(child: SingleChildScrollView(controller: _leftPaneScrollController, padding: const EdgeInsets.fromLTRB(18, 22, 18, 20), child: Column(key: _childKey, children: children))),
          ]),
          if (outgoing)
            Positioned(bottom: 14, left: 18, child: InkWell(onTap: () {
              if (DesktopSettingPage.tabKeys.isNotEmpty) DesktopSettingPage.switch2page(DesktopSettingPage.tabKeys[0]);
            }, onHover: (v) => _editHover.value = v, child: Obx(() => Icon(Icons.settings_outlined, color: _editHover.value ? Colors.white : Colors.white60, size: 22)))),
        ]),
      ),
    );
  }

  Widget _buildAproxiaBrand() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF60C7FF), Color(0xFF0878E8)]), boxShadow: [BoxShadow(color: const Color(0xFF1598F6).withOpacity(.35), blurRadius: 20)]),
          child: Stack(alignment: Alignment.center, children: [
            Transform.rotate(angle: -.52, child: Container(width: 15, height: 47, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)))),
            Transform.rotate(angle: .52, child: Container(width: 15, height: 47, decoration: BoxDecoration(color: Colors.white.withOpacity(.82), borderRadius: BorderRadius.circular(9)))),
            Positioned(bottom: 13, child: Container(width: 30, height: 8, decoration: BoxDecoration(color: const Color(0xFF0B2D55), borderRadius: BorderRadius.circular(6)))),
          ]),
        ),
        const SizedBox(height: 12),
        const Text(AproxiaBrand.name, style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -.5)),
        const SizedBox(height: 3),
        const Text(AproxiaBrand.tagline, style: TextStyle(color: Color(0xFF9BD8FF), fontSize: 12)),
        const SizedBox(height: 18),
        Container(height: 1, color: Colors.white12),
      ]),
    );
  }

  Widget _sidebarCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.075), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(.12))),
    child: child,
  );

  buildRightPane(BuildContext context) => const ConnectionPage();

  buildIDBoard(BuildContext context) {
    final model = gFFI.serverModel;
    return _sidebarCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.desktop_windows_outlined, color: Color(0xFF8FD3FF), size: 18), SizedBox(width: 8), Text('Acest dispozitiv', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))]),
      const SizedBox(height: 15),
      const Text('ID-UL TĂU', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: GestureDetector(onDoubleTap: () { Clipboard.setData(ClipboardData(text: model.serverId.text)); showToast(translate('Copied')); }, child: TextFormField(controller: model.serverId, readOnly: true, decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero), style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: 1.1)).workaroundFreezeLinuxMint())),
        IconButton(tooltip: 'Copiază ID', onPressed: () { Clipboard.setData(ClipboardData(text: model.serverId.text)); showToast(translate('Copied')); }, icon: const Icon(Icons.copy_rounded, color: Color(0xFF8FD3FF), size: 19)),
        buildPopupMenu(context),
      ]),
    ])).marginOnly(bottom: 12);
  }

  Widget buildPopupMenu(BuildContext context) {
    return IconButton(onPressed: DesktopTabPage.onAddSetting, tooltip: translate('Settings'), icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20));
  }

  buildPasswordBoard(BuildContext context) => ChangeNotifierProvider.value(value: gFFI.serverModel, child: Consumer<ServerModel>(builder: (context, model, child) => buildPasswordBoard2(context, model)));

  buildPasswordBoard2(BuildContext context, ServerModel model) {
    final showOneTime = model.approveMode != 'click' && model.verificationMethod != kUsePermanentPassword;
    return _sidebarCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('PAROLĂ TEMPORARĂ', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
      const SizedBox(height: 5),
      Row(children: [
        Expanded(child: GestureDetector(onDoubleTap: () { if (showOneTime) { Clipboard.setData(ClipboardData(text: model.serverPasswd.text)); showToast(translate('Copied')); } }, child: TextFormField(controller: model.serverPasswd, readOnly: true, decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero), style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 1.2)).workaroundFreezeLinuxMint())),
        if (showOneTime) AnimatedRotationWidget(onPressed: () => bind.mainUpdateTemporaryPassword(), child: const Icon(Icons.refresh_rounded, color: Color(0xFF8FD3FF), size: 20)),
        if (!bind.isDisableSettings()) IconButton(tooltip: translate('Change Password'), onPressed: () => DesktopSettingPage.switch2page(SettingsTabKey.safety), icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 19)),
      ]),
    ])).marginOnly(bottom: 12);
  }

  Widget _buildLocalActions() {
    return Column(children: [
      SizedBox(width: double.infinity, height: 42, child: ElevatedButton.icon(onPressed: () { final m = gFFI.serverModel; Clipboard.setData(ClipboardData(text: '${m.serverId.text} | ${m.serverPasswd.text}')); showToast(translate('Copied')); }, icon: const Icon(Icons.link_rounded, size: 18), label: const Text('Copiază datele de conectare'), style: ElevatedButton.styleFrom(backgroundColor: AproxiaBrand.accent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, height: 40, child: OutlinedButton.icon(onPressed: DesktopTabPage.onAddSetting, icon: const Icon(Icons.tune_rounded, size: 18), label: const Text('Setări avansate'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
    ]).marginOnly(bottom: 8);
  }

  buildTip(BuildContext context) => const SizedBox.shrink();

  Widget buildHelpCards(String updateUrl) {
    if (systemError.isNotEmpty) return buildInstallCard('', systemError, '', () {});
    if (isWindows && !bind.isDisableInstallation()) {
      if (!bind.mainIsInstalled()) return buildInstallCard('', bind.isOutgoingOnly() ? '' : 'install_tip', 'Install', () async { await rustDeskWinManager.closeAllSubWindows(); bind.mainGotoInstall(); });
      if (bind.mainIsInstalledLowerVersion()) return buildInstallCard('Status', 'Your installation is lower version.', 'Click to upgrade', () async { await rustDeskWinManager.closeAllSubWindows(); bind.mainUpdateMe(); });
    } else if (isMacOS) {
      final outgoing = bind.isOutgoingOnly();
      if (!(outgoing || bind.mainIsCanScreenRecording(prompt: false))) return buildInstallCard('Permissions', 'config_screen', 'Configure', () async { bind.mainIsCanScreenRecording(prompt: true); watchIsCanScreenRecording = true; });
      if (!outgoing && !bind.mainIsProcessTrusted(prompt: false)) return buildInstallCard('Permissions', 'config_acc', 'Configure', () async { bind.mainIsProcessTrusted(prompt: true); watchIsProcessTrust = true; });
      if (!bind.mainIsCanInputMonitoring(prompt: false)) return buildInstallCard('Permissions', 'config_input', 'Configure', () async { bind.mainIsCanInputMonitoring(prompt: true); watchIsInputMonitoring = true; });
    }
    if (bind.isIncomingOnly()) return Align(alignment: Alignment.centerRight, child: OutlinedButton(onPressed: () { SystemNavigator.pop(); if (isWindows) exit(0); }, child: Text(translate('Quit')))).marginAll(14);
    return const SizedBox.shrink();
  }

  Widget buildInstallCard(String title, String content, String btnText, GestureTapCallback onPressed, {double marginTop = 14, String? help, String? link, bool? closeButton, String? closeOption}) {
    return Container(
      margin: EdgeInsets.only(top: marginTop), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AproxiaBrand.warning.withOpacity(.14), borderRadius: BorderRadius.circular(12), border: Border.all(color: AproxiaBrand.warning.withOpacity(.35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title.isNotEmpty) Text(translate(title), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        if (content.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(translate(content), style: const TextStyle(color: Colors.white70, fontSize: 12))),
        if (btnText.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: OutlinedButton(onPressed: onPressed, child: Text(translate(btnText)))),
      ]),
    );
  }

  @override
  void initState() {
    super.initState();
    _updateTimer = periodic_immediate(const Duration(seconds: 1), () async {
      await gFFI.serverModel.fetchID();
      final error = await bind.mainGetError();
      if (systemError != error) { systemError = error; setState(() {}); }
      final v = await mainGetBoolOption(kOptionStopService);
      if (v != svcStopped.value) { svcStopped.value = v; setState(() {}); }
      if (watchIsCanScreenRecording && bind.mainIsCanScreenRecording(prompt: false)) { watchIsCanScreenRecording = false; setState(() {}); }
      if (watchIsProcessTrust && bind.mainIsProcessTrusted(prompt: false)) { watchIsProcessTrust = false; setState(() {}); }
      if (watchIsInputMonitoring && bind.mainIsCanInputMonitoring(prompt: false)) { watchIsInputMonitoring = false; setState(() {}); }
      if (watchIsCanRecordAudio) {
        if (isMacOS) {
          Future.microtask(() async { if ((await osxCanRecordAudio() == PermissionAuthorizeType.authorized)) { watchIsCanRecordAudio = false; setState(() {}); } });
        } else { watchIsCanRecordAudio = false; setState(() {}); }
      }
    });
    Get.put<RxBool>(svcStopped, tag: 'stop-service');
    rustDeskWinManager.registerActiveWindowListener(onActiveWindowChanged);
    screenToMap(window_size.Screen screen) => {'frame': {'l': screen.frame.left, 't': screen.frame.top, 'r': screen.frame.right, 'b': screen.frame.bottom}, 'visibleFrame': {'l': screen.visibleFrame.left, 't': screen.visibleFrame.top, 'r': screen.visibleFrame.right, 'b': screen.visibleFrame.bottom}, 'scaleFactor': screen.scaleFactor};
    bool isChattyMethod(String methodName) => methodName == kWindowBumpMouse;
    rustDeskWinManager.setMethodHandler((call, fromWindowId) async {
      if (!isChattyMethod(call.method)) debugPrint('[Main] call ${call.method} with args ${call.arguments} from window $fromWindowId');
      if (call.method == kWindowMainWindowOnTop) windowOnTop(null);
      else if (call.method == kWindowRefreshCurrentUser) gFFI.userModel.refreshCurrentUser();
      else if (call.method == kWindowGetScreenList) return jsonEncode((await window_size.getScreenList()).map(screenToMap).toList());
      else if (call.method == kWindowActionRebuild) reloadCurrentWindow();
      else if (call.method == kWindowEventShow) await rustDeskWinManager.registerActiveWindow(call.arguments['id']);
      else if (call.method == kWindowEventHide) await rustDeskWinManager.unregisterActiveWindow(call.arguments['id']);
      else if (call.method == kWindowConnect) await connectMainDesktop(call.arguments['id'], isFileTransfer: call.arguments['isFileTransfer'], isViewCamera: call.arguments['isViewCamera'], isTerminal: call.arguments['isTerminal'], isTcpTunneling: call.arguments['isTcpTunneling'], isRDP: call.arguments['isRDP'], password: call.arguments['password'], forceRelay: call.arguments['forceRelay'], connToken: call.arguments['connToken']);
      else if (call.method == kWindowBumpMouse) return RdPlatformChannel.instance.bumpMouse(dx: call.arguments['dx'], dy: call.arguments['dy']);
      else if (call.method == kWindowEventMoveTabToNewWindow) {
        final args = call.arguments.split(',');
        final windowId = int.tryParse(args[0]);
        WindowType? windowType;
        try { windowType = WindowType.values.byName(args[3]); } catch (_) {}
        if (windowId != null && windowType != null) await rustDeskWinManager.moveTabToNewWindow(windowId, args[1], args[2], windowType);
      } else if (call.method == kWindowEventOpenMonitorSession) {
        final args = jsonDecode(call.arguments); await rustDeskWinManager.openMonitorSession(args['window_id'] as int, args['peer_id'] as String, args['display'] as int, args['display_count'] as int, parseParamScreenRect(args), args['window_type'] as int);
      } else if (call.method == kWindowEventRemoteWindowCoords) {
        final windowId = int.tryParse(call.arguments); if (windowId != null) return jsonEncode(await rustDeskWinManager.getOtherRemoteWindowCoords(windowId));
      }
    });
    _uniLinksSubscription = listenUniLinks();
    if (bind.isIncomingOnly()) WidgetsBinding.instance.addPostFrameCallback((_) => _updateWindowSize());
    WidgetsBinding.instance.addObserver(this);
  }

  _updateWindowSize() {
    final renderObject = _childKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final size = renderObject.size;
      if (size != imcomingOnlyHomeSize) { imcomingOnlyHomeSize = size; windowManager.setSize(getIncomingOnlyHomeSize()); }
    }
  }

  @override
  void dispose() {
    _uniLinksSubscription?.cancel(); Get.delete<RxBool>(tag: 'stop-service'); _updateTimer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state); if (state == AppLifecycleState.resumed) shouldBeBlocked(_block, canBeBlocked);
  }
}

void setPasswordDialog({VoidCallback? notEmptyCallback}) async {
  final p0 = TextEditingController(text: '');
  final p1 = TextEditingController(text: '');
  var errMsg0 = '';
  var errMsg1 = '';
  final localPasswordSet = (await bind.mainGetCommon(key: 'local-permanent-password-set')) == 'true';
  final permanentPasswordSet = (await bind.mainGetCommon(key: 'permanent-password-set')) == 'true';
  final presetPassword = permanentPasswordSet && !localPasswordSet;
  var canSubmit = false;
  final RxString rxPass = ''.obs;
  final rules = [DigitValidationRule(), UppercaseValidationRule(), LowercaseValidationRule(), MinCharactersValidationRule(8)];
  final maxLength = bind.mainMaxEncryptLen();
  final statusTip = localPasswordSet ? translate('password-hidden-tip') : (presetPassword ? translate('preset-password-in-use-tip') : '');
  final showStatusTipOnMobile = statusTip.isNotEmpty && !isDesktop && !isWebDesktop;
  gFFI.dialogManager.show((setState, close, context) {
    updateCanSubmit() { canSubmit = p0.text.trim().isNotEmpty || p1.text.trim().isNotEmpty; }
    submit() async {
      if (!canSubmit) return;
      setState(() { errMsg0 = ''; errMsg1 = ''; });
      final pass = p0.text.trim();
      if (pass.isNotEmpty) {
        final violations = rules.where((r) => !r.validate(pass));
        if (violations.isNotEmpty) { setState(() => errMsg0 = '${translate('Prompt')}: ${violations.map((r) => r.name).join(', ')}'); return; }
      }
      if (p1.text.trim() != pass) { setState(() => errMsg1 = '${translate('Prompt')}: ${translate('The confirmation is not identical.')}'); return; }
      final ok = await bind.mainSetPermanentPasswordWithResult(password: pass);
      if (!ok) { setState(() => errMsg0 = '${translate('Prompt')}: ${translate('Failed')}'); return; }
      if (pass.isNotEmpty) notEmptyCallback?.call(); close();
    }
    return CustomAlertDialog(
      title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.key, color: AproxiaBrand.accent), Text(translate('Set Password')).paddingOnly(left: 10)]),
      content: ConstrainedBox(constraints: const BoxConstraints(minWidth: 500), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: showStatusTipOnMobile ? 0 : 6),
        TextField(obscureText: true, decoration: InputDecoration(labelText: translate('Password'), errorText: errMsg0.isNotEmpty ? errMsg0 : null), controller: p0, autofocus: true, onChanged: (value) { rxPass.value = value.trim(); setState(() { errMsg0 = ''; updateCanSubmit(); }); }, maxLength: maxLength).workaroundFreezeLinuxMint(),
        PasswordStrengthIndicator(password: rxPass),
        TextField(obscureText: true, decoration: InputDecoration(labelText: translate('Confirmation'), errorText: errMsg1.isNotEmpty ? errMsg1 : null), controller: p1, onChanged: (_) { setState(() { errMsg1 = ''; updateCanSubmit(); }); }, maxLength: maxLength).workaroundFreezeLinuxMint(),
        if (statusTip.isNotEmpty) Text(statusTip, style: const TextStyle(fontSize: 13)),
      ])),
      actions: [dialogButton('Cancel', icon: const Icon(Icons.close_rounded), onPressed: close, isOutline: true), if (localPasswordSet) dialogButton('Remove', icon: const Icon(Icons.delete_outline_rounded), onPressed: () async { final ok = await bind.mainSetPermanentPasswordWithResult(password: ''); if (ok) close(); }, buttonStyle: const ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.red))), dialogButton('OK', icon: const Icon(Icons.done_rounded), onPressed: canSubmit ? submit : null)],
      onSubmit: canSubmit ? submit : null,
      onCancel: close,
    );
  });
}
