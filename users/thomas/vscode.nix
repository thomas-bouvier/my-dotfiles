{ pkgs, lib, ... }:
{
  # The Nordic package does a better job at theming VSCode
  stylix.targets.vscode.enable = false;

  programs.vscodium = {
    enable = true;
    package = pkgs.unstable.vscodium;
    mutableExtensionsDir = false;

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions = with pkgs.nix-vscode-extensions.open-vsx-release; [
        # IDE
        vscodevim.vim
        marlosirapuan.nord-deep
        mk12.better-git-line-blame
        bierner.markdown-preview-github-styles
        pkief.material-icon-theme
        detachhead.basedpyright
        ms-toolsai.jupyter 
        flox.flox
        tomoki1207.pdf

        # Python
        ms-python.python
        charliermarsh.ruff
        astral-sh.ty
        marimo-team.vscode-marimo

        # Languages
        jnoortheen.nix-ide
        vue.volar
        opentofu.vscode-opentofu
      ];

      userSettings = {
        # Theming
        "workbench.colorTheme" = lib.mkForce "Nord Deep";
        "workbench.iconTheme" = "material-icon-theme";
        "chat.viewSessions.orientation" = "stacked";
        "editor.fontSize" = lib.mkForce 13;
        "explorer.confirmDelete" = true;
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;
        "chat.disableAIFeatures" = true;

        # marimo: the bundled WASM language server is spawned via
        # ELECTRON_RUN_AS_NODE on the VSCodium binary, but our VSCodium
        # (1.126) ignores that variable, so the server never starts
        # (-32097 loop). Run it with a real Node instead. The path is
        # taken from the extension derivation so it tracks the installed
        # version.
        "marimo.lsp.server" = "custom";
        "marimo.lsp.path" = [
          "${pkgs.nodejs}/bin/node"
          "${pkgs.nix-vscode-extensions.open-vsx-release.marimo-team.vscode-marimo}/share/vscode/extensions/marimo-team.vscode-marimo/dist/wasmServer.js"
        ];

        # marimo runs `uv --version` at startup and shows a popup when
        # no uv can be executed (its bundled binary is not ELF-patched
        # on NixOS). Point it at Nixpkgs' uv.
        "marimo.uv.path" = "${pkgs.uv}/bin/uv";
      };
    };
  };
}
