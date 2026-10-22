# Nord theme for Signal Desktop (https://www.nordtheme.com).
# Applied via commonOverlays in flake.nix; nord.css holds the actual theme.
#
# Replaces `signal-desktop` with a themed build: the app.asar shipped by the
# upstream nixpkgs package is unpacked, nord.css is appended to the app's main
# stylesheet, and the archive is repacked. The upstream launcher wrapper is
# reused with only the asar path rewritten, so Electron version bumps in
# nixpkgs don't require changes here. The upstream binary itself is taken
# from the Nix binary cache — no app rebuild, so this stays cheap.
#
# Nord is applied through Signal's own theming hooks:
#   - `--axo-color-*` design tokens (new UI, light and dark modes)
#   - `.dark-theme`-scoped fallbacks for legacy SCSS components
# Per-conversation chat colors are kept; an opt-in block at the bottom of
# nord.css switches outgoing bubbles to flat nord10.
#
# Maintenance: a nixpkgs Signal bump re-applies the theme automatically.
# nord.css only needs a touch if Signal renames its CSS classes/tokens
# upstream. `passthru.unthemed` keeps the stock package reachable.
final: prev: {
  signal-desktop = prev.stdenv.mkDerivation {
    pname = "signal-desktop-nord";
    inherit (prev.signal-desktop) version;

    nativeBuildInputs = [ prev.asar ];

    buildCommand = ''
      mkdir -p $out
      cp -r --no-preserve=mode ${prev.signal-desktop}/share $out/share

      # Inject the Nord theme into the app's main stylesheet
      appDir=$(mktemp -d)
      asar extract "$out/share/signal-desktop/app.asar" "$appDir"
      cat ${./nord.css} >> "$appDir/stylesheets/manifest.css"
      rm "$out/share/signal-desktop/app.asar"
      asar pack "$appDir" "$out/share/signal-desktop/app.asar"

      # Reuse upstream's wrapper, pointing at the patched asar
      mkdir -p $out/bin
      substitute "${prev.signal-desktop}/bin/signal-desktop" "$out/bin/signal-desktop" \
        --replace-fail "${prev.signal-desktop}/share/signal-desktop/app.asar" "$out/share/signal-desktop/app.asar"
      chmod +x $out/bin/signal-desktop
    '';

    passthru.unthemed = prev.signal-desktop;

    inherit (prev.signal-desktop) meta;
  };
}
