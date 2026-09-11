import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/aproxia_brand.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/custom_password.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:flutter_hbb/utils/platform_channel.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart' as window_size;

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({Key? key}) : super(key: key);

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
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
  final RxBool _block = false.obs;
  final GlobalKey _childKey = GlobalKey();
  String _selectedNav = 'home';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final incoming = bind.isIncomingOnly();
    return _buildBlock(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(context, incoming: incoming),
          if (!incoming) const Expanded(child: ConnectionPage()),
        ],
      ),
    );
  }

  Widget _buildBlock({required Widget child}) => buildRemoteBlock(
        block: _block,
        mask: true,
        use: canBeBlocked,
        child: child,
      );

  Widget _buildSidebar(BuildContext context, {required bool incoming}) {
    return Container(
      key: _childKey,
      width: incoming ? 310 : 308,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B2B58), Color(0xFF061A35)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _SidebarGlobePainter())),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 28, 15, 18),
              child: Column(
                children: [
                  _brandHeader(),
                  const SizedBox(height: 34),
                  _navItem('home', Icons.home_rounded, 'Acasă'),
                  _navItem('connect', Icons.phonelink_rounded, 'Conectare'),
                  _navItem('devices', Icons.desktop_windows_rounded, 'Dispozitivele mele'),
                  _navItem('history', Icons.history_rounded, 'Istoric'),
                  _navItem('agenda', Icons.group_outlined, 'Agendă'),
                  const SizedBox(height: 8),
                  _navItem('settings', Icons.settings_outlined, 'Setări'),
                  const Spacer(),
                  if (!incoming) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, bottom: 4),
                        child: Text(
                          'Conectăm oamenii.',
                          style: TextStyle(color: Color(0xFF8ED9FF), fontSize: 15),
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, bottom: 22),
                        child: Text(
                          'Apropiem distanțele.',
                          style: TextStyle(color: Color(0xFF8ED9FF), fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        AproxiaBrand.versionLabel,
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const Spacer(),
                      if (incoming)
                        IconButton(
                          tooltip: 'Ieșire',
                          hoverColor: const Color(0xFF123F75),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onPressed: () {
                            SystemNavigator.pop();
                            if (isWindows) exit(0);
                          },
                          icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 19),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandHeader() {
    return const Column(
      children: [
        AproxiaMark(size: 86, showTile: false),
        SizedBox(height: 7),
        Text(
          'Aproxia',
          style: TextStyle(
            color: Colors.white,
            fontSize: 31,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Calculatoarele tale. Oriunde.',
          style: TextStyle(color: Color(0xFF9DE0FF), fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _navItem(String key, IconData icon, String label) {
    final selected = _selectedNav == key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected ? const Color(0xFF1F66C2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: selected ? const Color(0xFF1F66C2) : const Color(0xFF123F75),
          focusColor: const Color(0xFF123F75),
          splashColor: const Color(0x332F82E8),
          highlightColor: Colors.transparent,
          onTap: () {
            if (key == 'settings') {
              setState(() => _selectedNav = key);
              DesktopSettingPage.switch2page(SettingsTabKey.general);
              return;
            }
            setState(() => _selectedNav = key);
            if (key == 'home') {
              ConnectionPage.requestSection('home');
            } else {
              ConnectionPage.requestSection(key);
            }
          },
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Icon(icon, color: Colors.white, size: 25),
                const SizedBox(width: 17),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _updateTimer = periodic_immediate(const Duration(seconds: 1), () async {
      await gFFI.serverModel.fetchID();
      final error = await bind.mainGetError();
      if (systemError != error && mounted) {
        systemError = error;
        setState(() {});
      }
      final v = await mainGetBoolOption(kOptionStopService);
      if (v != svcStopped.value) {
        svcStopped.value = v;
        if (mounted) setState(() {});
      }
      if (watchIsCanScreenRecording && bind.mainIsCanScreenRecording(prompt: false)) {
        watchIsCanScreenRecording = false;
        if (mounted) setState(() {});
      }
      if (watchIsProcessTrust && bind.mainIsProcessTrusted(prompt: false)) {
        watchIsProcessTrust = false;
        if (mounted) setState(() {});
      }
      if (watchIsInputMonitoring && bind.mainIsCanInputMonitoring(prompt: false)) {
        watchIsInputMonitoring = false;
        if (mounted) setState(() {});
      }
      if (watchIsCanRecordAudio) {
        if (isMacOS) {
          Future.microtask(() async {
            if ((await osxCanRecordAudio() == PermissionAuthorizeType.authorized)) {
              watchIsCanRecordAudio = false;
              if (mounted) setState(() {});
            }
          });
        } else {
          watchIsCanRecordAudio = false;
          if (mounted) setState(() {});
        }
      }
    });

    Get.put<RxBool>(svcStopped, tag: 'stop-service');
    rustDeskWinManager.registerActiveWindowListener(onActiveWindowChanged);

    screenToMap(window_size.Screen screen) => {
          'frame': {
            'l': screen.frame.left,
            't': screen.frame.top,
            'r': screen.frame.right,
            'b': screen.frame.bottom,
          },
          'visibleFrame': {
            'l': screen.visibleFrame.left,
            't': screen.visibleFrame.top,
            'r': screen.visibleFrame.right,
            'b': screen.visibleFrame.bottom,
          },
          'scaleFactor': screen.scaleFactor,
        };

    bool isChattyMethod(String methodName) => methodName == kWindowBumpMouse;

    rustDeskWinManager.setMethodHandler((call, fromWindowId) async {
      if (!isChattyMethod(call.method)) {
        debugPrint('[Main] call ${call.method} with args ${call.arguments} from window $fromWindowId');
      }
      if (call.method == kWindowMainWindowOnTop) {
        windowOnTop(null);
      } else if (call.method == kWindowRefreshCurrentUser) {
        gFFI.userModel.refreshCurrentUser();
      } else if (call.method == kWindowGetScreenList) {
        return jsonEncode((await window_size.getScreenList()).map(screenToMap).toList());
      } else if (call.method == kWindowActionRebuild) {
        reloadCurrentWindow();
      } else if (call.method == kWindowEventShow) {
        await rustDeskWinManager.registerActiveWindow(call.arguments['id']);
      } else if (call.method == kWindowEventHide) {
        await rustDeskWinManager.unregisterActiveWindow(call.arguments['id']);
      } else if (call.method == kWindowConnect) {
        await connectMainDesktop(
          call.arguments['id'],
          isFileTransfer: call.arguments['isFileTransfer'],
          isViewCamera: call.arguments['isViewCamera'],
          isTerminal: call.arguments['isTerminal'],
          isTcpTunneling: call.arguments['isTcpTunneling'],
          isRDP: call.arguments['isRDP'],
          password: call.arguments['password'],
          forceRelay: call.arguments['forceRelay'],
          connToken: call.arguments['connToken'],
        );
      } else if (call.method == kWindowBumpMouse) {
        return RdPlatformChannel.instance.bumpMouse(
          dx: call.arguments['dx'],
          dy: call.arguments['dy'],
        );
      } else if (call.method == kWindowEventMoveTabToNewWindow) {
        final args = call.arguments.split(',');
        final windowId = int.tryParse(args[0]);
        WindowType? windowType;
        try {
          windowType = WindowType.values.byName(args[3]);
        } catch (_) {}
        if (windowId != null && windowType != null) {
          await rustDeskWinManager.moveTabToNewWindow(
            windowId,
            args[1],
            args[2],
            windowType,
          );
        }
      } else if (call.method == kWindowEventOpenMonitorSession) {
        final args = jsonDecode(call.arguments);
        await rustDeskWinManager.openMonitorSession(
          args['window_id'] as int,
          args['peer_id'] as String,
          args['display'] as int,
          args['display_count'] as int,
          parseParamScreenRect(args),
          args['window_type'] as int,
        );
      } else if (call.method == kWindowEventRemoteWindowCoords) {
        final windowId = int.tryParse(call.arguments);
        if (windowId != null) {
          return jsonEncode(await rustDeskWinManager.getOtherRemoteWindowCoords(windowId));
        }
      }
    });

    _uniLinksSubscription = listenUniLinks();
    if (bind.isIncomingOnly()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateWindowSize());
    }
    WidgetsBinding.instance.addObserver(this);
  }

  _updateWindowSize() {
    final renderObject = _childKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final size = renderObject.size;
      if (size != imcomingOnlyHomeSize) {
        imcomingOnlyHomeSize = size;
        windowManager.setSize(getIncomingOnlyHomeSize());
      }
    }
  }

  @override
  void dispose() {
    _uniLinksSubscription?.cancel();
    Get.delete<RxBool>(tag: 'stop-service');
    _updateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      shouldBeBlocked(_block, canBeBlocked);
    }
  }
}

class _SidebarGlobePainter extends CustomPainter {
  const _SidebarGlobePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .20, size.height * .84);
    final radius = size.width * .67;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF128CFF).withOpacity(.30),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.25));
    canvas.drawCircle(center, radius * 1.25, glow);

    final line = Paint()
      ..color = const Color(0xFF42B5FF).withOpacity(.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, line);
    for (var i = -2; i <= 2; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * (0.35 + i.abs() * .18),
        ),
        line,
      );
    }
    for (var i = -2; i <= 2; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * .28);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * .75,
          height: radius * 2,
        ),
        line,
      );
      canvas.restore();
    }
    final arc = Paint()
      ..color = const Color(0xFF8DDCFF).withOpacity(.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final path = Path()
      ..moveTo(size.width * .03, size.height * .78)
      ..quadraticBezierTo(
        size.width * .60,
        size.height * .58,
        size.width * 1.05,
        size.height * .48,
      );
    canvas.drawPath(path, arc);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void setPasswordDialog({VoidCallback? notEmptyCallback}) async {
  final p0 = TextEditingController(text: '');
  final p1 = TextEditingController(text: '');
  var errMsg0 = '';
  var errMsg1 = '';
  final localPasswordSet =
      (await bind.mainGetCommon(key: 'local-permanent-password-set')) == 'true';
  final permanentPasswordSet =
      (await bind.mainGetCommon(key: 'permanent-password-set')) == 'true';
  final presetPassword = permanentPasswordSet && !localPasswordSet;
  var canSubmit = false;
  final RxString rxPass = ''.obs;
  final rules = [
    DigitValidationRule(),
    UppercaseValidationRule(),
    LowercaseValidationRule(),
    MinCharactersValidationRule(8),
  ];
  final maxLength = bind.mainMaxEncryptLen();
  final statusTip = localPasswordSet
      ? 'Parola permanentă este setată local.'
      : (presetPassword ? 'Este utilizată parola presetată.' : '');

  gFFI.dialogManager.show((setState, close, context) {
    updateCanSubmit() {
      canSubmit = p0.text.trim().isNotEmpty || p1.text.trim().isNotEmpty;
    }

    submit() async {
      if (!canSubmit) return;
      setState(() {
        errMsg0 = '';
        errMsg1 = '';
      });
      final pass = p0.text.trim();
      if (pass.isNotEmpty) {
        final violations = rules.where((r) => !r.validate(pass));
        if (violations.isNotEmpty) {
          setState(() => errMsg0 = 'Parola nu respectă toate cerințele de securitate.');
          return;
        }
      }
      if (p1.text.trim() != pass) {
        setState(() => errMsg1 = 'Confirmarea parolei nu este identică.');
        return;
      }
      final ok = await bind.mainSetPermanentPasswordWithResult(password: pass);
      if (!ok) {
        setState(() => errMsg0 = 'Parola nu a putut fi salvată.');
        return;
      }
      if (pass.isNotEmpty) notEmptyCallback?.call();
      close();
    }

    return CustomAlertDialog(
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.key, color: AproxiaBrand.accent),
          SizedBox(width: 10),
          Text('Setează parola'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Parolă',
                errorText: errMsg0.isNotEmpty ? errMsg0 : null,
              ),
              controller: p0,
              autofocus: true,
              onChanged: (value) {
                rxPass.value = value.trim();
                setState(() {
                  errMsg0 = '';
                  updateCanSubmit();
                });
              },
              maxLength: maxLength,
            ).workaroundFreezeLinuxMint(),
            PasswordStrengthIndicator(password: rxPass),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmare',
                errorText: errMsg1.isNotEmpty ? errMsg1 : null,
              ),
              controller: p1,
              onChanged: (_) {
                setState(() {
                  errMsg1 = '';
                  updateCanSubmit();
                });
              },
              maxLength: maxLength,
            ).workaroundFreezeLinuxMint(),
            if (statusTip.isNotEmpty)
              Text(statusTip, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      actions: [
        dialogButton(
          'Anulează',
          icon: const Icon(Icons.close_rounded),
          onPressed: close,
          isOutline: true,
        ),
        if (localPasswordSet)
          dialogButton(
            'Elimină',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await bind.mainSetPermanentPasswordWithResult(password: '');
              if (ok) close();
            },
            buttonStyle: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(Colors.red),
            ),
          ),
        dialogButton(
          'Salvează',
          icon: const Icon(Icons.done_rounded),
          onPressed: canSubmit ? submit : null,
        ),
      ],
      onSubmit: canSubmit ? submit : null,
      onCancel: close,
    );
  });
}
