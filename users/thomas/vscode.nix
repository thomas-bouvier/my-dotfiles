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

      extensions =
        with pkgs.nix-vscode-extensions.open-vsx-release; [
          # IDE
          vscodevim.vim
          marlosirapuan.nord-deep
          mk12.better-git-line-blame
          bierner.markdown-preview-github-styles
          pkief.material-icon-theme
          detachhead.basedpyright
          mistralai.mistral-vibe-code

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
      };
    };
  };
}
