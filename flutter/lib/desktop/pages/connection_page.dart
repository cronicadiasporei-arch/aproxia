import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/aproxia_brand.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/widgets/peer_tab_page.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class OnlineStatusWidget extends StatefulWidget {
  const OnlineStatusWidget({Key? key, this.onSvcStatusChanged, this.compact = true})
      : super(key: key);
  final VoidCallback? onSvcStatusChanged;
  final bool compact;

  @override
  State<OnlineStatusWidget> createState() => _OnlineStatusWidgetState();
}

class _OnlineStatusWidgetState extends State<OnlineStatusWidget> {
  final _svcStopped = Get.find<RxBool>(tag: 'stop-service');
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _updateTimer = periodic_immediate(const Duration(seconds: 1), updateStatus);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ready =
          !_svcStopped.value && stateGlobal.svcStatus.value == SvcStatus.ready;
      final connecting = stateGlobal.svcStatus.value == SvcStatus.connecting;
      final color = ready
          ? AproxiaBrand.success
          : connecting
              ? AproxiaBrand.warning
              : AproxiaBrand.danger;
      final label = _svcStopped.value
          ? 'Serviciu oprit'
          : connecting
              ? 'Se conectează...'
              : stateGlobal.svcStatus.value == SvcStatus.notReady
                  ? 'Indisponibil'
                  : 'Conectat la rețea';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.compact ? 8 : 11,
            height: widget.compact ? 8 : 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: widget.compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: AproxiaBrand.text,
            ),
          ),
          if (_svcStopped.value) ...[
            const SizedBox(width: 8),
            InkWell(
              hoverColor: const Color(0xFFE8F2FF),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () => start_service(true),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: Text(
                  'Pornește',
                  style: TextStyle(
                    color: AproxiaBrand.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Future<void> updateStatus() async {
    widget.onSvcStatusChanged?.call();
    try {
      final status =
          jsonDecode(await bind.mainGetConnectStatus()) as Map<String, dynamic>;
      final statusNum = status['status_num'] as int;
      stateGlobal.svcStatus.value = statusNum == 1
          ? SvcStatus.ready
          : statusNum == 0
              ? SvcStatus.connecting
              : SvcStatus.notReady;
      try {
        stateGlobal.videoConnCount.value = status['video_conn_count'] as int;
      } catch (_) {}
    } catch (_) {}
  }
}

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({Key? key}) : super(key: key);

  static final ValueNotifier<String> navigationRequest =
      ValueNotifier<String>('home');
  static void requestSection(String section) =>
      navigationRequest.value = '$section-${DateTime.now().microsecondsSinceEpoch}';

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage>
    with SingleTickerProviderStateMixin, WindowListener {
  final _idController = IDTextEditingController();
  final RxBool _idInputFocused = false.obs;
  final FocusNode _idFocusNode = FocusNode();
  final TextEditingController _idEditingController = TextEditingController();
  final GlobalKey _connectKey = GlobalKey();
  final GlobalKey _devicesKey = GlobalKey();
  final GlobalKey _recentKey = GlobalKey();
  bool isWindowMinimized = false;
  String _lastRemoteId = '';

  @override
  void initState() {
    super.initState();
    _idFocusNode.addListener(onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lastRemoteId = await bind.mainGetLastRemoteId();
      if (!mounted) return;
      setState(() {
        _lastRemoteId = lastRemoteId;
        if (_idController.id.isEmpty) _idController.id = lastRemoteId;
      });
    });
    Get.put<TextEditingController>(_idEditingController);
    Get.put<IDTextEditingController>(_idController);
    ConnectionPage.navigationRequest.addListener(_handleNavigationRequest);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    ConnectionPage.navigationRequest.removeListener(_handleNavigationRequest);
    _idController.dispose();
    windowManager.removeListener(this);
    _idFocusNode.removeListener(onFocusChanged);
    _idFocusNode.dispose();
    _idEditingController.dispose();
    if (Get.isRegistered<IDTextEditingController>()) {
      Get.delete<IDTextEditingController>();
    }
    if (Get.isRegistered<TextEditingController>()) {
      Get.delete<TextEditingController>();
    }
    super.dispose();
  }

  void _handleNavigationRequest() {
    final request = ConnectionPage.navigationRequest.value.split('-').first;
    if (request == 'home') {
      final ctx = _connectKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0,
        );
      }
      return;
    }

    GlobalKey? key;
    if (request == 'connect') key = _connectKey;
    if (request == 'devices' || request == 'agenda') key = _devicesKey;
    if (request == 'history') key = _recentKey;
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: .08,
      );
    }
    if (request == 'connect') {
      Future.delayed(
        const Duration(milliseconds: 380),
        () => _idFocusNode.requestFocus(),
      );
    }
  }

  void onFocusChanged() {
    _idInputFocused.value = _idFocusNode.hasFocus;
    if (_idFocusNode.hasFocus) {
      final len = _idEditingController.value.text.length;
      _idEditingController.selection =
          TextSelection(baseOffset: 0, extentOffset: len);
    }
  }

  @override
  void onWindowEvent(String eventName) {
    super.onWindowEvent(eventName);
    if (eventName == 'minimize') {
      isWindowMinimized = true;
    } else if (eventName == 'maximize' || eventName == 'restore') {
      if (isWindowMinimized && isWindows) Get.forceAppUpdate();
      isWindowMinimized = false;
    }
  }

  @override
  void onWindowEnterFullScreen() => stateGlobal.resizeEdgeSize.value = 0;

  @override
  void onWindowLeaveFullScreen() {
    stateGlobal.resizeEdgeSize.value = stateGlobal.isMaximized.isTrue
        ? kMaximizeEdgeSize
        : windowResizeEdgeSize;
  }

  @override
  void onWindowClose() {
    super.onWindowClose();
    bind.mainOnMainWindowClose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Container(
        color: AproxiaBrand.canvas,
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _WorldGlowPainter())),
            ),
            Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 780;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(30, 28, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHero(),
                            const SizedBox(height: 24),
                            wide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 12,
                                        child: Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 6,
                                                  child: _buildThisDevice(),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  flex: 5,
                                                  child: _buildConnectCard(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            _buildDevices(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      SizedBox(width: 220, child: _buildRecent()),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildThisDevice(),
                                      const SizedBox(height: 16),
                                      _buildConnectCard(),
                                      const SizedBox(height: 16),
                                      _buildRecent(),
                                      const SizedBox(height: 16),
                                      _buildDevices(),
                                    ],
                                  ),
                            const SizedBox(height: 26),
                            _buildFeatureFooter(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acces la distanță. Fără limite.',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w800,
                  color: AproxiaBrand.text,
                  letterSpacing: -.8,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Sigur. Rapid. Oriunde în lume.',
                style: TextStyle(
                  fontSize: 22,
                  color: AproxiaBrand.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const OnlineStatusWidget(compact: false),
            const SizedBox(height: 34),
            Text(
              '« Tehnologia care\nte ține aproape. »',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AproxiaBrand.text.withOpacity(.82),
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
    Key? key,
  }) {
    return Container(
      key: key,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AproxiaBrand.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF153B73).withOpacity(.06),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildThisDevice() {
    return Consumer<ServerModel>(builder: (context, model, _) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Acest dispozitiv',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AproxiaBrand.text,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AproxiaBrand.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                const Flexible(
                  child: Text(
                    'Pregătit pentru conexiuni',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AproxiaBrand.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _identityBox('ID-ul tău', model.serverId, true)),
                const SizedBox(width: 12),
                Expanded(
                  child: _identityBox(
                    'Parolă temporară',
                    model.serverPasswd,
                    false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 270,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: '${model.serverId.text} | ${model.serverPasswd.text}',
                        ),
                      );
                      showToast('Date de conectare copiate');
                    },
                    icon: const Icon(Icons.link_rounded, size: 19),
                    label: const Text(
                      'Copiază datele de conectare',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: _primaryStyle(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () => DesktopSettingPage.switch2page(
                        SettingsTabKey.general,
                      ),
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text(
                        'Setări avansate',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: _outlineStyle(),
                    ),
                  ),
                ),
              ],
            ),
            if (isWindows &&
                !bind.isDisableInstallation() &&
                !bind.mainIsInstalled()) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                style: _textButtonStyle(),
                onPressed: bind.mainGotoInstall,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Instalează Aproxia pentru acces complet prin UAC',
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _identityBox(
    String label,
    TextEditingController controller,
    bool id,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0EAF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AproxiaBrand.text,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, value, __) => SelectableText(
                    value.text.isEmpty ? 'Se generează…' : value.text,
                    maxLines: 1,
                    style: TextStyle(
                      color: value.text.isEmpty
                          ? AproxiaBrand.muted
                          : AproxiaBrand.text,
                      fontSize: id ? 24 : 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: id ? 1.0 : .8,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: id ? 'Copiază ID-ul' : 'Copiază parola',
                hoverColor: const Color(0xFFE2EDFB),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.text));
                  showToast(id ? 'ID copiat' : 'Parolă copiată');
                },
                icon: const Icon(
                  Icons.copy_rounded,
                  color: AproxiaBrand.text,
                  size: 20,
                ),
              ),
              if (!id)
                IconButton(
                  tooltip: 'Generează o parolă nouă',
                  hoverColor: const Color(0xFFE2EDFB),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: bind.mainUpdateTemporaryPassword,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AproxiaBrand.accent,
                    size: 23,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectCard() {
    return _card(
      key: _connectKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conectează-te la un dispozitiv',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AproxiaBrand.text,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _buildIdField()),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {},
                  style: _outlineStyle(),
                  child: const Icon(
                    Icons.star_border_rounded,
                    color: AproxiaBrand.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.near_me_outlined, size: 20),
              label: const Text(
                'Conectează-te',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: _primaryStyle(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _secondaryAction(
                  Icons.description_outlined,
                  'Transfer fișiere',
                  () => onConnect(isFileTransfer: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _secondaryAction(
                  Icons.person_search_outlined,
                  'Acces neasistat',
                  () => DesktopSettingPage.switch2page(SettingsTabKey.safety),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdField() {
    return RawAutocomplete<Peer>(
      optionsBuilder: (value) => const Iterable<Peer>.empty(),
      focusNode: _idFocusNode,
      textEditingController: _idEditingController,
      fieldViewBuilder: (context, controller, focus, submit) {
        updateTextAndPreserveSelection(controller, _idController.text);
        return Obx(
          () => TextField(
            controller: controller,
            focusNode: focus,
            inputFormatters: [IDTextInputFormatter()],
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            cursorColor: AproxiaBrand.accent,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AproxiaBrand.text,
            ),
            decoration: InputDecoration(
              hintText:
                  _idInputFocused.value ? null : 'Introdu ID-ul dispozitivului',
              hintStyle: const TextStyle(
                color: Color(0xFF7185A2),
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.white,
              hoverColor: const Color(0xFFF7FAFF),
              focusColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AproxiaBrand.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AproxiaBrand.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AproxiaBrand.accent,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (v) => _idController.id = v,
            onSubmitted: (_) => onConnect(),
          ),
        );
      },
      onSelected: (_) {},
      optionsViewBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecent() {
    return _card(
      key: _recentKey,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: SizedBox(
        height: 430,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conexiuni recente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AproxiaBrand.text,
              ),
            ),
            const SizedBox(height: 18),
            if (_lastRemoteId.isNotEmpty)
              _recentItem(_lastRemoteId, 'Ultima conexiune', true)
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'Conexiunile tale recente\nvor apărea aici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AproxiaBrand.muted, height: 1.5),
                  ),
                ),
              ),
            const Spacer(),
            TextButton.icon(
              style: _textButtonStyle(),
              onPressed: () => ConnectionPage.requestSection('devices'),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Vezi istoricul complet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentItem(String id, String subtitle, bool online) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor: const Color(0xFFF0F6FF),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () {
          _idController.id = id;
          _idEditingController.text = id;
          ConnectionPage.requestSection('connect');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.computer_rounded,
                  color: AproxiaBrand.accent,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AproxiaBrand.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: online
                                ? AproxiaBrand.success
                                : AproxiaBrand.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AproxiaBrand.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.more_vert_rounded,
                color: AproxiaBrand.muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevices() {
    return _card(
      key: _devicesKey,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dispozitivele mele',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AproxiaBrand.text,
                ),
              ),
              Spacer(),
              Text(
                'Recente · Favorite · Agendă',
                style: TextStyle(fontSize: 12, color: AproxiaBrand.muted),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(height: 245, child: PeerTabPage()),
        ],
      ),
    );
  }

  Widget _buildFeatureFooter() {
    const items = <(IconData, String)>[
      (Icons.verified_user_outlined, 'Conexiune criptată end-to-end'),
      (Icons.group_outlined, 'Control complet'),
      (Icons.bolt_outlined, 'Performanță ridicată'),
      (Icons.language_rounded, 'Pentru uz personal și profesional'),
    ];
    return Container(
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AproxiaBrand.border)),
      ),
      child: Row(
        children: [
          for (final item in items) ...[
            Icon(item.$1, color: const Color(0xFF456B9F), size: 22),
            const SizedBox(width: 8),
            Text(
              item.$2,
              style: const TextStyle(color: Color(0xFF45618A), fontSize: 12),
            ),
            const SizedBox(width: 22),
          ],
          const Spacer(),
          const Text(
            AproxiaBrand.versionLabel,
            style: TextStyle(color: AproxiaBrand.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  ButtonStyle _primaryStyle() => ButtonStyle(
        elevation: const MaterialStatePropertyAll(0),
        foregroundColor: const MaterialStatePropertyAll(Colors.white),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return const Color(0xFFAFC3E8);
          }
          if (states.contains(MaterialState.hovered)) {
            return const Color(0xFF246BE0);
          }
          if (states.contains(MaterialState.pressed)) {
            return const Color(0xFF1D5CC5);
          }
          return AproxiaBrand.accent;
        }),
        overlayColor: const MaterialStatePropertyAll(Colors.transparent),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  ButtonStyle _outlineStyle() => ButtonStyle(
        elevation: const MaterialStatePropertyAll(0),
        foregroundColor: const MaterialStatePropertyAll(AproxiaBrand.text),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) {
            return const Color(0xFFEAF3FF);
          }
          if (states.contains(MaterialState.pressed)) {
            return const Color(0xFFDCEBFF);
          }
          return Colors.white;
        }),
        overlayColor: const MaterialStatePropertyAll(Colors.transparent),
        side: const MaterialStatePropertyAll(
          BorderSide(color: AproxiaBrand.border),
        ),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  ButtonStyle _textButtonStyle() => ButtonStyle(
        foregroundColor: const MaterialStatePropertyAll(AproxiaBrand.accent),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) {
            return const Color(0xFFEAF3FF);
          }
          return Colors.transparent;
        }),
        overlayColor: const MaterialStatePropertyAll(Colors.transparent),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  Widget _secondaryAction(
    IconData icon,
    String label,
    VoidCallback action,
  ) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: action,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        style: _outlineStyle(),
      ),
    );
  }

  void onConnect({
    bool isFileTransfer = false,
    bool isViewCamera = false,
    bool isTerminal = false,
    bool isTcpTunneling = false,
  }) {
    final id = _idEditingController.text.trim().isNotEmpty
        ? _idEditingController.text.trim()
        : _idController.id;
    connect(
      context,
      id,
      isFileTransfer: isFileTransfer,
      isViewCamera: isViewCamera,
      isTerminal: isTerminal,
      isTcpTunneling: isTcpTunneling,
    );
  }
}

class _WorldGlowPainter extends CustomPainter {
  const _WorldGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8FC8FF).withOpacity(.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.width * .62, size.height * .09);
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: 330 + i * 70,
          height: 115 + i * 25,
        ),
        paint,
      );
    }
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7AC7FF).withOpacity(.16),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 360));
    canvas.drawCircle(center, 360, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
