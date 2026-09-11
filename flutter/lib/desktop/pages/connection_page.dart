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
  const OnlineStatusWidget({Key? key, this.onSvcStatusChanged}) : super(key: key);
  final VoidCallback? onSvcStatusChanged;

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
                  : 'Online';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AproxiaBrand.text)),
          if (_svcStopped.value) ...[
            const SizedBox(width: 8),
            InkWell(onTap: () => start_service(true), child: const Text('Pornește', style: TextStyle(color: AproxiaBrand.accent, fontWeight: FontWeight.w600))),
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
      color: AproxiaBrand.canvas,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 26, 30, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  const SizedBox(height: 22),
                  _buildStatusStrip(),
                  const SizedBox(height: 16),
                  _buildQuickConnect(context),
                  const SizedBox(height: 16),
                  _buildPeersSection(),
                ],
              ),
            ),
          ),
          if (!isOutgoingOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 11),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AproxiaBrand.border))),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, size: 17, color: AproxiaBrand.accent),
                  SizedBox(width: 8),
                  Text('Conexiune securizată', style: TextStyle(fontSize: 12, color: AproxiaBrand.muted)),
                  Spacer(),
                  OnlineStatusWidget(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Acces la distanță, simplu și sigur.',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AproxiaBrand.text, letterSpacing: -.45),
        ),
        SizedBox(height: 5),
        Text('Conectează-te la calculatoarele tale oriunde te-ai afla.', style: TextStyle(fontSize: 15, color: AproxiaBrand.muted)),
      ],
    );
  }

  Widget _buildStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5E7FB)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.verified_user_outlined, color: AproxiaBrand.success, size: 19),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aproxia este pregătit pentru conexiuni', style: TextStyle(fontWeight: FontWeight.w700, color: AproxiaBrand.text, fontSize: 14)),
                SizedBox(height: 2),
                Text('Sesiuni protejate, conexiune rapidă și suport pentru mai multe dispozitive.', style: TextStyle(color: AproxiaBrand.muted, fontSize: 12)),
              ],
            ),
          ),
          const OnlineStatusWidget(),
        ],
      ),
    );
  }

  Widget _premiumCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(20)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AproxiaBrand.radiusMedium),
        border: Border.all(color: AproxiaBrand.border),
        boxShadow: [BoxShadow(color: AproxiaBrand.ink.withOpacity(.045), blurRadius: 20, offset: const Offset(0, 7))],
      ),
      child: child,
    );
  }

  Widget _buildQuickConnect(BuildContext context) {
    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.near_me_outlined, color: AproxiaBrand.accent, size: 21),
              SizedBox(width: 10),
              Text('Conectare rapidă', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AproxiaBrand.text)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Introdu ID-ul computerului la care vrei să te conectezi.', style: TextStyle(fontSize: 12, color: AproxiaBrand.muted)),
          const SizedBox(height: 15),
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
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AproxiaBrand.text),
                    decoration: InputDecoration(
                      hintText: _idInputFocused.value ? null : 'ID dispozitiv',
                      hintStyle: const TextStyle(color: Color(0xFFA6B4C5)),
                      prefixIcon: const Icon(Icons.computer_outlined, color: AproxiaBrand.accent),
                      filled: true,
                      fillColor: const Color(0xFFF8FBFF),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AproxiaBrand.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AproxiaBrand.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AproxiaBrand.accent, width: 1.4)),
                    ),
                    onChanged: (v) => _idController.id = v,
                    onSubmitted: (_) => onConnect(),
                  ));
            },
            onSelected: (_) {},
            optionsViewBuilder: (context, onSelected, options) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.near_me_outlined, size: 18),
              label: const Text('Conectează-te', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AproxiaBrand.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(child: _secondaryAction(Icons.folder_copy_outlined, 'Transfer fișiere', () => onConnect(isFileTransfer: true))),
              const SizedBox(width: 10),
              Expanded(child: _secondaryAction(Icons.terminal_rounded, 'Terminal', () => onConnect(isTerminal: true))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secondaryAction(IconData icon, String label, VoidCallback action) {
    return SizedBox(
      height: 42,
      child: Material(
        color: const Color(0xFFF2F6FC),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AproxiaBrand.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: AproxiaBrand.text),
                const SizedBox(width: 8),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AproxiaBrand.text, fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeersSection() {
    return _premiumCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.devices_other_outlined, color: AproxiaBrand.accent, size: 21),
              SizedBox(width: 9),
              Text('Dispozitive & recente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AproxiaBrand.text)),
            ],
          ),
          SizedBox(height: 5),
          Text('Accesează rapid calculatoarele folosite recent, favoritele și agenda ta.', style: TextStyle(fontSize: 12, color: AproxiaBrand.muted)),
          SizedBox(height: 12),
          SizedBox(height: 250, child: PeerTabPage()),
        ],
      ),
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
