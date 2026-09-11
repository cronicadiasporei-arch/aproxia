from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def replace(path, old, new):
    p = ROOT / path
    s = p.read_text(encoding='utf-8')
    if old not in s:
        print(f'[aproxia-v1.0.1-2] warning: pattern not found in {path}: {old[:90]!r}')
        return
    p.write_text(s.replace(old, new), encoding='utf-8')
    print(f'[aproxia-v1.0.1-2] patched {path}')

# Sidebar: keep the artwork decorative only. Put version and language in their
# own opaque footer so they can never overlap the globe/slogan artwork.
replace(
    'flutter/lib/desktop/pages/desktop_home_page.dart',
    """                  if (!incoming) ...[
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
                  ),""",
    """                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF061A35).withOpacity(.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x334FC3FF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language_rounded, color: Color(0xFF8ED9FF), size: 17),
                        const SizedBox(width: 7),
                        Text(
                          translate('Language'),
                          style: const TextStyle(color: Color(0xFFC9DDF5), fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Text(
                          AproxiaBrand.versionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
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
                  ),""",
)

# Settings must follow the selected light/dark theme. The previous patch forced
# a light canvas while upstream controls still used dark-theme foregrounds,
# which created white-on-white content.
settings = ROOT / 'flutter/lib/desktop/pages/desktop_setting_page.dart'
s = settings.read_text(encoding='utf-8')
s = s.replace("backgroundColor: const Color(0xFFF4F8FD),", "backgroundColor: Theme.of(context).colorScheme.background,")
s = s.replace("color: const Color(0xFFF4F8FD),", "color: Theme.of(context).scaffoldBackgroundColor,")
s = s.replace("            color: Colors.white,\n            shape: RoundedRectangleBorder", "            color: null,\n            shape: RoundedRectangleBorder")
settings.write_text(s, encoding='utf-8')
print('[aproxia-v1.0.1-2] settings theme contrast repaired')

# Installer: center all actions in one responsive Wrap and make Cancel return
# to the running application instead of terminating the process.
install = ROOT / 'flutter/lib/desktop/pages/install_page.dart'
s = install.read_text(encoding='utf-8')
s = s.replace(
    "onPressed: btnEnabled.value ? () => windowManager.close() : null,",
    "onPressed: btnEnabled.value ? () async { await windowManager.hide(); } : null,
)
s = s.replace(
    """                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [""",
    """                  Center(
                    child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [""",
)
s = s.replace(
    """                    ],
                  ),
                ],
              ),""",
    """                    ],
                    ),
                  ),
                ],
              ),""",
    1,
)
install.write_text(s, encoding='utf-8')
print('[aproxia-v1.0.1-2] installer actions aligned and cancel no longer exits')

print('[aproxia-v1.0.1-2] refinement patch complete')
