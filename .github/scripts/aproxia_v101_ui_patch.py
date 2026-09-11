from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def patch(path, replacements):
    p = ROOT / path
    s = p.read_text(encoding='utf-8')
    original = s
    for old, new in replacements:
        if old not in s:
            print(f'[aproxia-v1.0.1] warning: pattern not found in {path}: {old[:70]!r}')
        s = s.replace(old, new)
    if s != original:
        p.write_text(s, encoding='utf-8')
        print(f'[aproxia-v1.0.1] patched {path}')

# Premium dashboard artwork and layout.
patch('flutter/lib/desktop/pages/desktop_home_page.dart', [
    ("          const Positioned.fill(\n            child: IgnorePointer(child: CustomPaint(painter: _SidebarGlobePainter())),\n          ),",
     "          Positioned(\n            left: 0,\n            right: 0,\n            bottom: 0,\n            height: 430,\n            child: IgnorePointer(\n              child: Opacity(\n                opacity: .58,\n                child: Image.asset(\n                  AproxiaBrand.sidebarGlobeAsset,\n                  fit: BoxFit.cover,\n                  alignment: Alignment.bottomCenter,\n                  filterQuality: FilterQuality.high,\n                ),\n              ),\n            ),\n          ),"),
    ("                  const Spacer(),\n                  if (!incoming) ...[",
     "                  const Spacer(),\n                  if (!incoming && isWindows && !bind.isDisableInstallation() && !bind.mainIsInstalled()) ...[\n                    Padding(\n                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 14),\n                      child: Material(\n                        color: const Color(0xFF0E3970).withOpacity(.92),\n                        borderRadius: BorderRadius.circular(14),\n                        child: InkWell(\n                          borderRadius: BorderRadius.circular(14),\n                          hoverColor: const Color(0xFF174D91),\n                          onTap: bind.mainGotoInstall,\n                          child: const Padding(\n                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),\n                            child: Row(children: [\n                              Icon(Icons.download_for_offline_rounded, color: Color(0xFF72C8FF), size: 25),\n                              SizedBox(width: 11),\n                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [\n                                Text('Instalează Aproxia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),\n                                SizedBox(height: 2),\n                                Text('Acces complet și control UAC', style: TextStyle(color: Color(0xFFA9C8E9), fontSize: 10.5)),\n                              ])),\n                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),\n                            ]),\n                          ),\n                        ),\n                      ),\n                    ),\n                  ],\n                  if (!incoming) ...["),
    ("    return const Column(\n      children: [\n        AproxiaMark(size: 86, showTile: false),\n        SizedBox(height: 7),\n        Text(\n          'Aproxia',\n          style: TextStyle(\n            color: Colors.white,\n            fontSize: 31,\n            fontWeight: FontWeight.w800,\n            letterSpacing: -.7,\n          ),\n        ),\n        SizedBox(height: 2),\n        Text(\n          'Calculatoarele tale. Oriunde.',\n          style: TextStyle(color: Color(0xFF9DE0FF), fontSize: 12.5),\n        ),\n      ],\n    );",
     "    return Column(\n      children: [\n        Image.asset(\n          AproxiaBrand.logoAsset,\n          width: 218,\n          height: 128,\n          fit: BoxFit.contain,\n          filterQuality: FilterQuality.high,\n        ),\n      ],\n    );"),
])

patch('flutter/lib/desktop/pages/connection_page.dart', [
    ("            const Positioned.fill(\n              child: IgnorePointer(child: CustomPaint(painter: _WorldGlowPainter())),\n            ),",
     "            Positioned(\n              top: 0,\n              left: 0,\n              right: 0,\n              height: 235,\n              child: IgnorePointer(\n                child: Opacity(\n                  opacity: .30,\n                  child: Image.asset(\n                    AproxiaBrand.worldMapAsset,\n                    fit: BoxFit.cover,\n                    alignment: Alignment.topCenter,\n                    filterQuality: FilterQuality.high,\n                  ),\n                ),\n              ),\n            ),"),
    ("                      final wide = constraints.maxWidth >= 780;",
     "                      final wide = constraints.maxWidth >= 860;"),
    ("                        padding: const EdgeInsets.fromLTRB(30, 28, 24, 24),",
     "                        padding: EdgeInsets.fromLTRB(constraints.maxWidth < 900 ? 20 : 32, 28, constraints.maxWidth < 900 ? 20 : 28, 24),"),
    ("                SizedBox(\n                  width: 270,\n                  height: 46,",
     "                Expanded(\n                  child: SizedBox(\n                  height: 46,"),
    ("                    style: _primaryStyle(),\n                  ),\n                ),\n                const SizedBox(width: 12),\n                Expanded(",
     "                    style: _primaryStyle(),\n                  ),\n                  ),\n                ),\n                const SizedBox(width: 12),\n                Expanded("),
    ("            if (isWindows &&\n                !bind.isDisableInstallation() &&\n                !bind.mainIsInstalled()) ...[\n              const SizedBox(height: 10),\n              TextButton.icon(\n                style: _textButtonStyle(),\n                onPressed: bind.mainGotoInstall,\n                icon: const Icon(Icons.download_rounded, size: 18),\n                label: const Text(\n                  'Instalează Aproxia pentru acces complet prin UAC',\n                ),\n              ),\n            ],", ""),
    ("          SizedBox(height: 245, child: PeerTabPage()),",
     "          SizedBox(height: 300, child: PeerTabPage()),"),
    ("        child: SizedBox(\n        height: 430,", "        child: SizedBox(\n        height: 505,"),
])

# Rebrand settings/About while keeping upstream AGPL notices in source/licence files.
patch('flutter/lib/desktop/pages/desktop_setting_page.dart', [
    ("import 'package:flutter_hbb/common.dart';", "import 'package:flutter_hbb/common.dart';\nimport 'package:flutter_hbb/aproxia_brand.dart';"),
    ("const double _kTabWidth = 200;", "const double _kTabWidth = 224;"),
    ("const double _kCardFixedWidth = 540;", "const double _kCardFixedWidth = 680;"),
    ("tab, 'General',", "tab, 'General',"),
    ("tab, 'Security',", "tab, 'Security',"),
    ("_TabInfo(tab, 'About', Icons.info_outline, Icons.info)", "_TabInfo(tab, 'Despre Aproxia', Icons.info_outline, Icons.info)"),
    ("      backgroundColor: Theme.of(context).colorScheme.background,",
     "      backgroundColor: const Color(0xFFF4F8FD),"),
    ("              color: Theme.of(context).scaffoldBackgroundColor,",
     "              color: const Color(0xFFF4F8FD),"),
    ("        color: _accentColor,", "        color: AproxiaBrand.accent,"),
    ("          child: InkWell(\n          onTap:", "          child: InkWell(\n          hoverColor: const Color(0xFFEAF3FF),\n          splashColor: Colors.transparent,\n          highlightColor: Colors.transparent,\n          onTap:"),
    ("              color: selected ? _accentColor : null,", "              color: selected ? AproxiaBrand.accent : null,"),
    ("              color: selected ? _accentColor : null,", "              color: selected ? AproxiaBrand.accent : null,"),
    ("                  color: selected ? _accentColor : null,", "                  color: selected ? AproxiaBrand.accent : const Color(0xFF4E6585),"),
    ("        child: _Card(title: translate('About RustDesk'), children: [",
     "        child: _Card(title: 'Despre Aproxia', children: ["),
    ("      final version = data['version'].toString();", "      const version = AproxiaBrand.version;"),
    ("launchUrlString('https://rustdesk.com/privacy.html');", "launchUrlString('https://github.com/cronicadiasporei-arch/aproxia');"),
    ("launchUrlString('https://rustdesk.com');", "launchUrlString('https://github.com/cronicadiasporei-arch/aproxia');"),
    ("'Copyright © ${DateTime.now().toString().substring(0, 4)} Purslane Tech Pte. Ltd.\\n$license'",
     "'Aproxia ${AproxiaBrand.versionLabel}\\nSoftware open-source distribuit conform licenței AGPL-3.0.\\n$license'"),
    ("translate('Slogan_tip')", "'Acces la distanță. Fără limite.'"),
    ("decoration: const BoxDecoration(color: Color(0xFF2c8cff)),",
     "decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0B2B58), Color(0xFF1769E8)]), borderRadius: BorderRadius.circular(12)),"),
    ("          child: Card(\n            child: Column(",
     "          child: Card(\n            elevation: 0,\n            color: Colors.white,\n            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AproxiaBrand.border)),\n            child: Column("),
])

# Visible product-name leaks in common password/file-transfer dialogs.
for rel in [
    'flutter/lib/common/widgets/dialog.dart',
    'flutter/lib/common/widgets/connection_tabbar.dart',
    'flutter/lib/desktop/widgets/tabbar_widget.dart',
    'flutter/lib/desktop/pages/file_transfer_page.dart',
]:
    p = ROOT / rel
    if p.exists():
        s = p.read_text(encoding='utf-8')
        s2 = s.replace('Confirm RustDesk password', 'Confirm Aproxia password')
        s2 = s2.replace('RustDesk Password', 'Aproxia Password')
        s2 = s2.replace('RustDesk password', 'Aproxia password')
        s2 = s2.replace('RustDesk File Transfer', 'Aproxia File Transfer')
        if s2 != s:
            p.write_text(s2, encoding='utf-8')
            print(f'[aproxia-v1.0.1] rebranded {rel}')

# Make adaptive scaling the first-run default without overriding an explicit user choice.
main = ROOT / 'flutter/lib/main.dart'
s = main.read_text(encoding='utf-8')
needle = "WidgetsFlutterBinding.ensureInitialized();"
insert = """WidgetsFlutterBinding.ensureInitialized();
  // Aproxia: new installations start with adaptive remote scaling. Existing
  // explicit preferences are left untouched by the native option layer.
  try {
    final currentViewStyle = bind.mainGetUserDefaultOption(key: kOptionViewStyle);
    if (currentViewStyle.isEmpty) {
      await bind.mainSetUserDefaultOption(
        key: kOptionViewStyle,
        value: kRemoteViewStyleAdaptive,
      );
    }
  } catch (_) {}"""
if needle in s and 'Aproxia: new installations start with adaptive remote scaling' not in s:
    s = s.replace(needle, insert, 1)
    main.write_text(s, encoding='utf-8')
    print('[aproxia-v1.0.1] adaptive scaling default enabled')

print('[aproxia-v1.0.1] UI patch complete')
