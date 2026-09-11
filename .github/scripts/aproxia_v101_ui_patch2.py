from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def replace(path, old, new, label):
    p = ROOT / path
    s = p.read_text(encoding='utf-8')
    if old not in s:
        print(f'[aproxia-v1.0.1-2] warning: {label} pattern not found in {path}')
        return
    p.write_text(s.replace(old, new, 1), encoding='utf-8')
    print(f'[aproxia-v1.0.1-2] {label}: patched {path}')


# ---------------------------------------------------------------------------
# 1) Replace the blurry raster mini-logo with a clean vector Aproxia mark.
#    The full sidebar wordmark is rendered as real Flutter text, so it stays
#    sharp at every DPI instead of becoming unreadable on dark backgrounds.
# ---------------------------------------------------------------------------
brand_path = ROOT / 'flutter/lib/aproxia_brand.dart'
brand = brand_path.read_text(encoding='utf-8')
mark_start = brand.find('class AproxiaMark extends StatelessWidget')
if mark_start >= 0:
    brand = brand[:mark_start] + r'''class AproxiaMark extends StatelessWidget {
  const AproxiaMark({super.key, this.size = 64, this.showTile = false});

  final double size;
  final bool showTile;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size.square(size),
      painter: const _AproxiaMarkPainter(),
    );
    if (!showTile) return SizedBox.square(dimension: size, child: mark);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .08),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123F75), Color(0xFF061A35)],
        ),
        border: Border.all(color: const Color(0x554FC3FF)),
      ),
      child: mark,
    );
  }
}

class _AproxiaMarkPainter extends CustomPainter {
  const _AproxiaMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glow = Paint()
      ..color = const Color(0x3372C8FF)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .055);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .105
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF72C8FF), Color(0xFF2B7CFF), Color(0xFFFFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final a = Path()
      ..moveTo(w * .18, h * .82)
      ..lineTo(w * .50, h * .16)
      ..lineTo(w * .82, h * .82);
    canvas.drawPath(a, glow);
    canvas.drawPath(a, stroke);

    final cross = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .085
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF9DE0FF);
    canvas.drawLine(Offset(w * .34, h * .60), Offset(w * .66, h * .60), cross);

    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .045
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF4FC3FF);
    final orbitPath = Path()
      ..moveTo(w * .08, h * .68)
      ..cubicTo(w * .30, h * .89, w * .72, h * .82, w * .93, h * .45);
    canvas.drawPath(orbitPath, orbit);

    final sparkle = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * .84, h * .22), w * .035, sparkle);
    canvas.drawLine(Offset(w * .84, h * .12), Offset(w * .84, h * .32), Paint()..color = const Color(0xFF72C8FF)..strokeWidth = w * .025);
    canvas.drawLine(Offset(w * .74, h * .22), Offset(w * .94, h * .22), Paint()..color = const Color(0xFF72C8FF)..strokeWidth = w * .025);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
'''
    brand_path.write_text(brand, encoding='utf-8')
    print('[aproxia-v1.0.1-2] crisp vector Aproxia mark installed')


# ---------------------------------------------------------------------------
# 2) Sidebar: crisp wordmark + real language selector with flags.
# ---------------------------------------------------------------------------
home_path = ROOT / 'flutter/lib/desktop/pages/desktop_home_page.dart'
home = home_path.read_text(encoding='utf-8')
start = home.find('  Widget _brandHeader() {')
end = home.find('  Widget _navItem(', start)
if start >= 0 and end > start:
    home = home[:start] + r'''  Widget _brandHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          AproxiaMark(size: 68, showTile: false),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'APROXIA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Remote Access',
                  style: TextStyle(
                    color: Color(0xFF9DE0FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

''' + home[end:]
else:
    print('[aproxia-v1.0.1-2] warning: brand header bounds not found')

old_footer = r'''                  Row(
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
                  ),'''
new_footer = r'''                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF061A35).withOpacity(.94),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x334FC3FF)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PopupMenuButton<String>(
                            tooltip: 'Schimbă limba',
                            color: Colors.white,
                            offset: const Offset(0, -150),
                            onSelected: (key) async {
                              await bind.mainSetLocalOption(key: kCommConfKeyLang, value: key);
                              bind.mainChangeLanguage(lang: key);
                              reloadAllWindows();
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'ro',
                                child: Row(children: [Text('🇷🇴', style: TextStyle(fontSize: 20)), SizedBox(width: 10), Text('Română')]),
                              ),
                              PopupMenuItem(
                                value: 'it',
                                child: Row(children: [Text('🇮🇹', style: TextStyle(fontSize: 20)), SizedBox(width: 10), Text('Italiano')]),
                              ),
                              PopupMenuItem(
                                value: 'en',
                                child: Row(children: [Text('🇬🇧', style: TextStyle(fontSize: 20)), SizedBox(width: 10), Text('English')]),
                              ),
                            ],
                            child: Builder(builder: (_) {
                              final lang = bind.mainGetLocalOption(key: kCommConfKeyLang);
                              final flag = lang == 'it' ? '🇮🇹' : lang == 'en' ? '🇬🇧' : '🇷🇴';
                              final label = lang == 'it' ? 'Italiano' : lang == 'en' ? 'English' : 'Română';
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(flag, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 7),
                                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700))),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8ED9FF), size: 17),
                                ],
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          AproxiaBrand.versionLabel,
                          style: TextStyle(color: Colors.white60, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                        if (incoming) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Ieșire',
                            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                            padding: EdgeInsets.zero,
                            hoverColor: const Color(0xFF123F75),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onPressed: () {
                              SystemNavigator.pop();
                              if (isWindows) exit(0);
                            },
                            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 17),
                          ),
                        ],
                      ],
                    ),
                  ),'''
if old_footer in home:
    home = home.replace(old_footer, new_footer, 1)
    print('[aproxia-v1.0.1-2] real flag language selector installed')
else:
    print('[aproxia-v1.0.1-2] warning: sidebar footer pattern not found')
home_path.write_text(home, encoding='utf-8')


# ---------------------------------------------------------------------------
# 3) Dashboard: ID, password and connect controls stacked vertically.
# ---------------------------------------------------------------------------
connection_path = ROOT / 'flutter/lib/desktop/pages/connection_page.dart'
conn = connection_path.read_text(encoding='utf-8')

old_wide = r'''                                      Expanded(
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
                                      ),'''
new_wide = r'''                                      Expanded(
                                        flex: 12,
                                        child: Column(
                                          children: [
                                            _buildThisDevice(),
                                            const SizedBox(height: 14),
                                            _buildConnectCard(),
                                            const SizedBox(height: 16),
                                            _buildDevices(),
                                          ],
                                        ),
                                      ),'''
if old_wide in conn:
    conn = conn.replace(old_wide, new_wide, 1)
    print('[aproxia-v1.0.1-2] main connection cards stacked')
else:
    print('[aproxia-v1.0.1-2] warning: wide dashboard pattern not found')

old_identity = r'''            Row(
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
            ),'''
new_identity = r'''            _identityBox('ID-ul tău', model.serverId, true),
            const SizedBox(height: 12),
            _identityBox(
              'Parolă temporară',
              model.serverPasswd,
              false,
            ),'''
if old_identity in conn:
    conn = conn.replace(old_identity, new_identity, 1)
    print('[aproxia-v1.0.1-2] ID and password stacked')
else:
    print('[aproxia-v1.0.1-2] warning: identity row pattern not found')

# The first action row becomes a single clear primary action plus a compact
# advanced-settings action below it, avoiding clipped labels.
action_start = conn.find('            Row(\n              children: [\n                Expanded(\n                  child: SizedBox(\n                  height: 46,')
if action_start < 0:
    action_start = conn.find('            Row(\n              children: [\n                SizedBox(\n                  width: 270,')
action_end_marker = "            if (isWindows &&\n                !bind.isDisableInstallation()"
action_end = conn.find(action_end_marker, action_start) if action_start >= 0 else -1
if action_end < 0 and action_start >= 0:
    # patch1 removes the install CTA, so stop before the card's column closing.
    action_end = conn.find('          ],\n        ),\n      );', action_start)
if action_start >= 0 and action_end > action_start:
    replacement = r'''            SizedBox(
              width: double.infinity,
              height: 48,
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
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: _primaryStyle(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => DesktopSettingPage.switch2page(SettingsTabKey.general),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Setări avansate'),
                style: _textButtonStyle(),
              ),
            ),
'''
    conn = conn[:action_start] + replacement + conn[action_end:]
    print('[aproxia-v1.0.1-2] device actions simplified')
else:
    print('[aproxia-v1.0.1-2] warning: device action row bounds not found')

conn = conn.replace('SizedBox(width: 220, child: _buildRecent())', 'SizedBox(width: 248, child: _buildRecent())', 1)
connection_path.write_text(conn, encoding='utf-8')


# ---------------------------------------------------------------------------
# 4) Installer: Cancel returns to portable app, and all actions are vertical.
# ---------------------------------------------------------------------------
install_path = ROOT / 'flutter/lib/desktop/pages/install_page.dart'
install = install_path.read_text(encoding='utf-8')
install = install.replace(
    "onPressed: btnEnabled.value ? () => windowManager.close() : null,",
    "onPressed: btnEnabled.value ? () => bind.installRunWithoutInstall() : null,",
    1,
)

old_actions = r'''                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Obx(() => showProgress.value ? const LinearProgressIndicator() : const SizedBox.shrink()),
                      ),
                      Obx(() => OutlinedButton.icon(
                            icon: const Icon(Icons.close_rounded, size: 17),
                            label: const Text('Anulează'),
                            onPressed: btnEnabled.value ? () => bind.installRunWithoutInstall() : null,
                            style: buttonStyle,
                          )),
                      Obx(() => ElevatedButton.icon(
                            icon: const Icon(Icons.download_done_rounded, size: 17),
                            label: const Text('Instalează Aproxia'),
                            onPressed: btnEnabled.value ? install : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AproxiaBrand.accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFB8C8E8),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
                            )),
                      ),
                    ],
                  ),'''
new_actions = r'''                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 340,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Obx(() => showProgress.value
                              ? const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: LinearProgressIndicator(),
                                )
                              : const SizedBox.shrink()),
                          Obx(() => SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.download_done_rounded, size: 18),
                                  label: const Text('Instalează Aproxia'),
                                  onPressed: btnEnabled.value ? install : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AproxiaBrand.accent,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(0xFFB8C8E8),
                                    disabledForegroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 10),
                          Offstage(
                            offstage: bind.installShowRunWithoutInstall(),
                            child: Obx(() => SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.screen_share_outlined, size: 18),
                                    label: const Text('Rulează fără instalare'),
                                    onPressed: btnEnabled.value ? () => bind.installRunWithoutInstall() : null,
                                    style: buttonStyle,
                                  ),
                                )),
                          ),
                          const SizedBox(height: 8),
                          Obx(() => TextButton.icon(
                                icon: const Icon(Icons.arrow_back_rounded, size: 17),
                                label: const Text('Anulează și revino la Aproxia'),
                                onPressed: btnEnabled.value ? () => bind.installRunWithoutInstall() : null,
                                style: TextButton.styleFrom(
                                  foregroundColor: AproxiaBrand.muted,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),'''
if old_actions in install:
    install = install.replace(old_actions, new_actions, 1)
    print('[aproxia-v1.0.1-2] installer actions stacked; cancel returns to app')
else:
    print('[aproxia-v1.0.1-2] warning: installer action block pattern not found')
install_path.write_text(install, encoding='utf-8')

print('[aproxia-v1.0.1-2] requested UI corrections complete')
