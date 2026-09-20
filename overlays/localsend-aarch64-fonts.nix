# Fix blank text in LocalSend on aarch64-linux.
# https://github.com/localsend/localsend/issues/2873
# https://github.com/NixOS/nixpkgs/pull/540057
#
# LocalSend 1.18+ sets Linux to system 'Noto Sans' (and CJK variants).
# Those fonts are not loadable by Flutter on aarch64, so text stays blank.
# Bundle Roboto and force it as the Linux font family.
final: prev:
let
  inherit (prev.stdenv.hostPlatform) isAarch64 isLinux;
in
{
  localsend =
    if isAarch64 && isLinux then
      prev.localsend.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          mkdir -p fonts
          cp ${final.roboto}/share/fonts/truetype/Roboto-Regular.ttf fonts/
          cp ${final.roboto}/share/fonts/truetype/Roboto-Medium.ttf fonts/
          cp ${final.roboto}/share/fonts/truetype/Roboto-Bold.ttf fonts/
          cp ${final.roboto}/share/fonts/truetype/Roboto-Italic.ttf fonts/
          cp ${final.roboto}/share/fonts/truetype/Roboto-BoldItalic.ttf fonts/

          substituteInPlace pubspec.yaml \
            --replace-fail '  uses-material-design: true' '  uses-material-design: true
            fonts:
              - family: Roboto
                fonts:
                  - asset: fonts/Roboto-Regular.ttf
                  - asset: fonts/Roboto-Medium.ttf
                    weight: 500
                  - asset: fonts/Roboto-Bold.ttf
                    weight: 700
                  - asset: fonts/Roboto-Italic.ttf
                    style: italic
                  - asset: fonts/Roboto-BoldItalic.ttf
                    weight: 700
                    style: italic'

          # 1.18+ uses Noto Sans on Linux; force bundled Roboto instead.
          sed -i \
            -e "s/AppLocale.ja => 'Noto Sans CJK JP'/AppLocale.ja => 'Roboto'/" \
            -e "s/AppLocale.ko => 'Noto Sans CJK KR'/AppLocale.ko => 'Roboto'/" \
            -e "s/AppLocale.zhCn => 'Noto Sans CJK SC'/AppLocale.zhCn => 'Roboto'/" \
            -e "s/AppLocale.zhHk || AppLocale.zhTw => 'Noto Sans CJK TC'/AppLocale.zhHk || AppLocale.zhTw => 'Roboto'/" \
            -e "s/_ => 'Noto Sans'/_ => 'Roboto'/" \
            lib/config/theme.dart
        '';
      })
    else
      prev.localsend;
}
