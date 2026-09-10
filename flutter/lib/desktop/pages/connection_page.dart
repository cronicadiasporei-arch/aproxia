// main window right pane

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/aproxia_brand.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';
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
  final _svcIsUsingPublicServer = true.obs;
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
      final color = ready
          ? AproxiaBrand.success
          : stateGlobal.svcStatus.value == SvcStatus.connecting
              ? AproxiaBrand.warning
              : AproxiaBrand.danger;
      final label = _svcStopped.value
          ? translate('Service is not running')
          : stateGlobal.svcStatus.value == SvcStatus.connecting
              ? translate('connecting_status')
              : stateGlobal.svcStatus.value == SvcStatus.notReady
                  ? translate('not_ready_status')
                  : translate('Ready');
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (_svcStopped.value) ...[
            const SizedBox(width: 10),
            InkWell(onTap: () => start_service(true), child: Text(translate('Start service'), style: const TextStyle(color: AproxiaBrand.accent))),
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
    _svcIsUsingPublicServer.value = await bind.mainIsUsingPublicServer();
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
  final AllPeersLoader _allPeersLoader = AllPeersLoader();
  Iterable<Peer> _autocompleteOpts = [];
  bool isWindowMinimized = false;

  @override
  void initState() {
    super.initState();
    _allPeersLoader.init(setState);
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
    _allPeersLoader.clear();
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
      if (_allPeersLoader.needLoad) _allPeersLoader.getAllPeers();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  const SizedBox(height: 22),
                  LayoutBuilder(builder: (context, c) {
                    final narrow = c.maxWidth < 760;
                    final connect = _buildQuickConnect(context);
                    final security = _buildSecurityCard(context);
                    return narrow
                        ? Column(children: [connect, const SizedBox(height: 16), security])
                        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: connect), const SizedBox(width: 16), Expanded(flex: 2, child: security)]);
                  }),
                  const SizedBox(height: 18),
                  _buildPeersSection(),
                ],
              ),
            ),
          ),
          if (!isOutgoingOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
              child: Row(children: [const Icon(Icons.shield_outlined, size: 18, color: AproxiaBrand.accent), const SizedBox(width: 8), const Text('Conexiune securizată', style: TextStyle(fontSize: 12, color: Color(0xFF52657A))), const Spacer(), OnlineStatusWidget()]),
            ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Acces la distanță. Fără limite.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0B2B5B), letterSpacing: -0.5)),
            SizedBox(height: 5),
            Text('Sigur. Rapid. Oriunde în lume.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AproxiaBrand.accent)),
          ]),
        ),
        const Text(AproxiaBrand.tagline, style: TextStyle(fontSize: 12, color: Color(0xFF66809E), fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _premiumCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AproxiaBrand.radiusMedium),
        border: Border.all(color: const Color(0xFFDDE7F2)),
        boxShadow: [BoxShadow(color: const Color(0xFF0B2B5B).withOpacity(0.05), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }

  Widget _buildQuickConnect(BuildContext context) {
    return _premiumCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.near_me_outlined, color: AproxiaBrand.accent), SizedBox(width: 10), Text('Conectează-te la un dispozitiv', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF102A52)))]),
        const SizedBox(height: 16),
        RawAutocomplete<Peer>(
          optionsBuilder: (value) {
            if (value.text.isEmpty) return const Iterable<Peer>.empty();
            if (_allPeersLoader.peers.isEmpty && !_allPeersLoader.isPeersLoaded) return const Iterable<Peer>.empty();
            var query = value.text.replaceAll(' ', '');
            if (int.tryParse(query) == null) query = value.text;
            final q = query.toLowerCase();
            _autocompleteOpts = _allPeersLoader.peers.where((p) => p.id.toLowerCase().contains(q) || p.username.toLowerCase().contains(q) || p.hostname.toLowerCase().contains(q) || p.alias.toLowerCase().contains(q)).toList();
            _allPeersLoader.queryOnlines(_autocompleteOpts);
            return _autocompleteOpts;
          },
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: _idInputFocused.value ? null : 'Introdu ID-ul dispozitivului',
                prefixIcon: const Icon(Icons.computer_outlined),
                filled: true,
                fillColor: const Color(0xFFF8FBFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFD7E3F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFD7E3F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AproxiaBrand.accent, width: 1.5)),
              ),
              onChanged: (v) => _idController.id = v,
              onSubmitted: (_) => onConnect(),
            ));
          },
          onSelected: (peer) {
            setState(() => _idController.id = peer.id);
            FocusScope.of(context).unfocus();
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 420),
                child: ListView(shrinkWrap: true, children: options.map((p) => ListTile(leading: const Icon(Icons.computer), title: Text(p.alias.isNotEmpty ? p.alias : p.hostname), subtitle: Text(p.id), onTap: () => onSelected(p))).toList()),
              ),
            ),
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: onConnect,
            icon: const Icon(Icons.near_me_outlined),
            label: const Text('Conectează-te', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: AproxiaBrand.accent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _actionButton(Icons.description_outlined, 'Transfer fișiere', () => onConnect(isFileTransfer: true))),
          const SizedBox(width: 10),
          Expanded(child: _actionButton(Icons.terminal_outlined, 'Terminal', () => onConnect(isTerminal: true))),
        ]),
      ]),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback action) {
    return OutlinedButton.icon(
      onPressed: action,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF163A67), padding: const EdgeInsets.symmetric(vertical: 13), side: const BorderSide(color: Color(0xFFD7E3F0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    return _premiumCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Row(children: [Icon(Icons.security_outlined, color: AproxiaBrand.success), SizedBox(width: 9), Text('Pregătit pentru conexiuni', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF102A52)))]),
        SizedBox(height: 16),
        _FeatureLine(Icons.lock_outline, 'Sesiuni protejate', 'Controlul accesului rămâne activ.'),
        SizedBox(height: 13),
        _FeatureLine(Icons.speed_outlined, 'Performanță ridicată', 'Motorul remote Aproxia optimizează conexiunea.'),
        SizedBox(height: 13),
        _FeatureLine(Icons.devices_outlined, 'Multi-dispozitiv', 'Deschide și gestionează mai multe sesiuni.'),
      ]),
    );
  }

  Widget _buildPeersSection() {
    return _premiumCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Row(children: [Icon(Icons.devices_other_outlined, color: AproxiaBrand.accent), SizedBox(width: 9), Text('Dispozitivele mele & recente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF102A52)))]),
        SizedBox(height: 12),
        SizedBox(height: 330, child: PeerTabPage()),
      ]),
    );
  }

  void onConnect({bool isFileTransfer = false, bool isViewCamera = false, bool isTerminal = false, bool isTcpTunneling = false}) {
    connect(context, _idController.id, isFileTransfer: isFileTransfer, isViewCamera: isViewCamera, isTerminal: isTerminal, isTcpTunneling: isTcpTunneling);
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFEAF3FF), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 19, color: AproxiaBrand.accent)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF17365D))), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7F96), height: 1.25))])),
    ]);
  }
}
