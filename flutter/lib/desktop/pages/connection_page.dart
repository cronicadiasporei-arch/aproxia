import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/aproxia_brand.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_hbb/models/peer_model.dart';

import '../../common.dart';
import '../../common/formatter/id_formatter.dart';
import '../../common/widgets/peer_tab_page.dart';
import '../../models/platform_model.dart';

class OnlineStatusWidget extends StatefulWidget {
  const OnlineStatusWidget({Key? key, this.onSvcStatusChanged, this.compact = true}) : super(key: key);
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
      final ready = !_svcStopped.value && stateGlobal.svcStatus.value == SvcStatus.ready;
      final connecting = stateGlobal.svcStatus.value == SvcStatus.connecting;
      final color = ready ? AproxiaBrand.success : connecting ? AproxiaBrand.warning : AproxiaBrand.danger;
      final label = _svcStopped.value
          ? 'Serviciu oprit'
          : connecting
              ? 'Se conectează...'
              : stateGlobal.svcStatus.value == SvcStatus.notReady
                  ? 'Indisponibil'
                  : 'Conectat';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: widget.compact ? 8 : 12, height: widget.compact ? 8 : 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: widget.compact ? 12 : 14, fontWeight: FontWeight.w700, color: ready ? const Color(0xFF23853D) : AproxiaBrand.text)),
              if (!widget.compact && ready)
                const Text('Gata de utilizare', style: TextStyle(fontSize: 11, color: AproxiaBrand.muted)),
            ],
          ),
          if (_svcStopped.value) ...[
            const SizedBox(width: 8),
            InkWell(onTap: () => start_service(true), child: const Text('Pornește', style: TextStyle(color: AproxiaBrand.accent, fontWeight: FontWeight.w700))),
          ],
        ],
      );
    });
  }

  Future<void> updateStatus() async {
    widget.onSvcStatusChanged?.call();
    final status = jsonDecode(await bind.mainGetConnectStatus()) as Map<String, dynamic>;
    final statusNum = status['status_num'] as int;
    stateGlobal.svcStatus.value = statusNum == 1
        ? SvcStatus.ready
        : statusNum == 0
            ? SvcStatus.connecting
            : SvcStatus.notReady;
    try {
      stateGlobal.videoConnCount.value = status['video_conn_count'] as int;
    } catch (_) {}
  }
}

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({Key? key}) : super(key: key);

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage>
    with SingleTickerProviderStateMixin, WindowListener {
  final _idController = IDTextEditingController();
  final RxBool _idInputFocused = false.obs;
  final FocusNode _idFocusNode = FocusNode();
  final TextEditingController _idEditingController = TextEditingController();
  bool isWindowMinimized = false;

  @override
  void initState() {
    super.initState();
    _idFocusNode.addListener(onFocusChanged);
    if (_idController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final lastRemoteId = await bind.mainGetLastRemoteId();
        if (lastRemoteId != _idController.id && mounted) {
          setState(() => _idController.id = lastRemoteId);
        }
      });
    }
    Get.put<TextEditingController>(_idEditingController);
    Get.put<IDTextEditingController>(_idController);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    _idController.dispose();
    windowManager.removeListener(this);
    _idFocusNode.removeListener(onFocusChanged);
    _idFocusNode.dispose();
    _idEditingController.dispose();
    if (Get.isRegistered<IDTextEditingController>()) Get.delete<IDTextEditingController>();
    if (Get.isRegistered<TextEditingController>()) Get.delete<TextEditingController>();
    super.dispose();
  }

  void onFocusChanged() {
    _idInputFocused.value = _idFocusNode.hasFocus;
    if (_idFocusNode.hasFocus) {
      final len = _idEditingController.value.text.length;
      _idEditingController.selection = TextSelection(baseOffset: 0, extentOffset: len);
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
    stateGlobal.resizeEdgeSize.value = stateGlobal.isMaximized.isTrue ? kMaximizeEdgeSize : windowResizeEdgeSize;
  }

  @override
  void onWindowClose() {
    super.onWindowClose();
    bind.mainOnMainWindowClose();
  }

  @override
  Widget build(BuildContext context) {
    final isOutgoingOnly = bind.isOutgoingOnly();
    return Container(
      color: const Color(0xFFF4F8FD),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 820;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 18),
                      _buildStatusStrip(),
                      const SizedBox(height: 18),
                      wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildQuickConnect(context)),
                                const SizedBox(width: 18),
                                Expanded(flex: 2, child: _buildWhyAproxia()),
                              ],
                            )
                          : Column(
                              children: [
                                _buildQuickConnect(context),
                                const SizedBox(height: 16),
                                _buildWhyAproxia(),
                              ],
                            ),
                      const SizedBox(height: 18),
                      _buildPeersSection(),
                    ],
                  ),
                );
              },
            ),
          ),
          if (!isOutgoingOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AproxiaBrand.border))),
              child: Row(
                children: const [
                  Icon(Icons.circle, size: 12, color: AproxiaBrand.success),
                  SizedBox(width: 10),
                  Icon(Icons.lock_outline_rounded, size: 17, color: AproxiaBrand.text),
                  SizedBox(width: 7),
                  Text('Conexiune securizată', style: TextStyle(fontSize: 12, color: AproxiaBrand.muted)),
                  Spacer(),
                  Icon(Icons.info_outline_rounded, size: 16, color: AproxiaBrand.text),
                  SizedBox(width: 7),
                  Text('Aproxia v1.0.0 (Preview)', style: TextStyle(fontSize: 12, color: AproxiaBrand.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Acces la distanță, simplu și sigur.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AproxiaBrand.text, letterSpacing: -.55)),
              SizedBox(height: 5),
              Text('Conectează-te la calculatoarele tale oriunde te-ai afla.', style: TextStyle(fontSize: 15, color: AproxiaBrand.muted)),
            ],
          ),
        ),
        Text('Sigur. Rapid. De încredere.', style: TextStyle(fontSize: 13, color: AproxiaBrand.muted, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E7F7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.verified_user_rounded, color: AproxiaBrand.success, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aproxia este pregătit pentru conexiuni', style: TextStyle(fontWeight: FontWeight.w800, color: AproxiaBrand.text, fontSize: 14)),
                SizedBox(height: 2),
                Text('Sesiuni protejate, conexiune rapidă și suport pentru mai multe dispozitive.', style: TextStyle(color: AproxiaBrand.muted, fontSize: 12)),
              ],
            ),
          ),
          const OnlineStatusWidget(compact: false),
        ],
      ),
    );
  }

  Widget _premiumCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(22)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AproxiaBrand.border),
        boxShadow: [BoxShadow(color: AproxiaBrand.ink.withOpacity(.05), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    return ButtonStyle(
      elevation: const MaterialStatePropertyAll(0),
      backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.hovered) ? const Color(0xFFE8F1FF) : const Color(0xFFF5F8FD)),
      foregroundColor: const MaterialStatePropertyAll(AproxiaBrand.text),
      overlayColor: const MaterialStatePropertyAll(Colors.transparent),
      side: const MaterialStatePropertyAll(BorderSide(color: AproxiaBrand.border)),
      shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
    );
  }

  Widget _buildQuickConnect(BuildContext context) {
    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.near_me_rounded, color: AproxiaBrand.accent, size: 23),
              SizedBox(width: 10),
              Text('Conectare rapidă', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AproxiaBrand.text)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Introdu ID-ul computerului la care vrei să te conectezi.', style: TextStyle(fontSize: 12, color: AproxiaBrand.muted)),
          const SizedBox(height: 16),
          RawAutocomplete<Peer>(
            optionsBuilder: (value) => const Iterable<Peer>.empty(),
            focusNode: _idFocusNode,
            textEditingController: _idEditingController,
            fieldViewBuilder: (context, controller, focus, submit) {
              updateTextAndPreserveSelection(controller, _idController.text);
              return Obx(() => TextField(
                    controller: controller,
                    focusNode: focus,
                    inputFormatters: [IDTextInputFormatter()],
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AproxiaBrand.text),
                    decoration: InputDecoration(
                      hintText: _idInputFocused.value ? null : 'ID dispozitiv',
                      hintStyle: const TextStyle(color: Color(0xFFA8B5C7), fontWeight: FontWeight.w600),
                      prefixIcon: const Icon(Icons.desktop_windows_outlined, color: AproxiaBrand.text),
                      filled: true,
                      fillColor: const Color(0xFFF8FBFF),
                      contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AproxiaBrand.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AproxiaBrand.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AproxiaBrand.accent, width: 1.6)),
                    ),
                    onChanged: (v) => _idController.id = v,
                    onSubmitted: (_) => onConnect(),
                  ));
            },
            onSelected: (_) {},
            optionsViewBuilder: (context, onSelected, options) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.near_me_rounded, size: 19),
              label: const Text('Conectează-te', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AproxiaBrand.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB8C8E8),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _secondaryAction(Icons.description_outlined, 'Transfer fișiere', () => onConnect(isFileTransfer: true))),
              const SizedBox(width: 12),
              Expanded(child: _secondaryAction(Icons.terminal_rounded, 'Terminal', () => onConnect(isTerminal: true))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secondaryAction(IconData icon, String label, VoidCallback action) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: action,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        style: _secondaryButtonStyle(),
      ),
    );
  }

  Widget _buildWhyAproxia() {
    final items = <(IconData, String, String)>[
      (Icons.lock_rounded, 'Sesiuni protejate', 'Conexiune securizată end-to-end.'),
      (Icons.speed_rounded, 'Performanță ridicată', 'Conexiune rapidă și stabilă.'),
      (Icons.devices_other_rounded, 'Multi-dispozitiv', 'Accesează și gestionează mai multe dispozitive.'),
      (Icons.person_rounded, 'Ușor de folosit', 'Interfață simplă și intuitivă.'),
    ];
    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: AproxiaBrand.success, size: 23),
              SizedBox(width: 10),
              Text('De ce Aproxia?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AproxiaBrand.text)),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(12)),
                      child: Icon(item.$1, color: AproxiaBrand.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AproxiaBrand.text)),
                          const SizedBox(height: 2),
                          Text(item.$3, style: const TextStyle(fontSize: 12, height: 1.35, color: AproxiaBrand.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPeersSection() {
    return _premiumCard(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.desktop_windows_outlined, color: AproxiaBrand.accent, size: 23),
              const SizedBox(width: 10),
              const Expanded(child: Text('Dispozitive & recente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AproxiaBrand.text))),
              Container(
                width: 250,
                height: 42,
                decoration: BoxDecoration(color: const Color(0xFFF8FBFF), borderRadius: BorderRadius.circular(11), border: Border.all(color: AproxiaBrand.border)),
                child: const Row(
                  children: [
                    SizedBox(width: 12),
                    Icon(Icons.search_rounded, size: 21, color: AproxiaBrand.text),
                    SizedBox(width: 8),
                    Text('Caută dispozitive...', style: TextStyle(fontSize: 12, color: AproxiaBrand.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _viewButton(Icons.grid_view_rounded, true),
              const SizedBox(width: 6),
              _viewButton(Icons.view_list_rounded, false),
            ],
          ),
          const SizedBox(height: 5),
          const Text('Accesează rapid calculatoarele folosite recent, favoritele și agenda ta.', style: TextStyle(fontSize: 12, color: AproxiaBrand.muted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _sectionChip(Icons.schedule_rounded, 'Recente', true)),
              const SizedBox(width: 8),
              Expanded(child: _sectionChip(Icons.star_border_rounded, 'Favorite', false)),
              const SizedBox(width: 8),
              Expanded(child: _sectionChip(Icons.contacts_outlined, 'Agenda', false)),
              const SizedBox(width: 8),
              Expanded(child: _sectionChip(Icons.devices_rounded, 'Dispozitivele mele', false)),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 250, child: PeerTabPage()),
        ],
      ),
    );
  }

  Widget _sectionChip(IconData icon, String label, bool active) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: active ? AproxiaBrand.accent : const Color(0xFFF5F8FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? AproxiaBrand.accent : AproxiaBrand.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: active ? Colors.white : AproxiaBrand.text),
          const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AproxiaBrand.text))),
        ],
      ),
    );
  }

  Widget _viewButton(IconData icon, bool active) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: active ? AproxiaBrand.accent : const Color(0xFFF5F8FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? AproxiaBrand.accent : AproxiaBrand.border),
      ),
      child: Icon(icon, size: 19, color: active ? Colors.white : AproxiaBrand.text),
    );
  }

  void onConnect({bool isFileTransfer = false, bool isViewCamera = false, bool isTerminal = false, bool isTcpTunneling = false}) {
    connect(
      context,
      _idController.id,
      isFileTransfer: isFileTransfer,
      isViewCamera: isViewCamera,
      isTerminal: isTerminal,
      isTcpTunneling: isTcpTunneling,
    );
  }
}
