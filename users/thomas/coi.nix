# coi (code-on-incus) configuration.
#
# Runs AI coding agents inside isolated Incus containers (see system/coi.nix
# for the host-side setup). This file is the user-side config coi reads from
# ~/.coi/config.toml.
{ config, ... }:

let
  # home-manager manages these files as symlinks into the Nix store, and
  # bind-mounting a symlink would leave it dangling inside the container
  # (the store path does not exist there) — opencode would silently skip the
  # file. Mount the resolved store targets instead; the option re-resolves
  # on every rebuild, so the mounts track changes automatically.
  agentsMd = config.xdg.configFile."opencode/AGENTS.md".source;
  glmPlugin = config.xdg.configFile."opencode/plugins/mistral-glm-model.ts".source;
  # tui.json carries the theme ("nord"); coi's seeding pushes host symlinks
  # as-is (incus file push does not follow them), which left a dangling link
  # and the default theme inside the sandbox.
  tuiJson = config.xdg.configFile."opencode/tui.json".source;
in
{
  # coi runs the AI tool inside tmux, and tmux unconditionally sets each
  # pane's TERM to its default-terminal ("tmux-256color"), overriding the
  # TERM coi forwards. opencode's TUI emits no colors under tmux-256color,
  # which made the nord theme render unstyled in the sandbox. This forces
  # the pane TERM back to the standard xterm-256color (with COLORTERM
  # forwarded, opencode then renders full truecolor — verified by comparing
  # the emitted escape sequences with the host).
  home.file.".coi/tmux.conf".text = ''
    set -g default-terminal "xterm-256color"
    # tmux only passes 24-bit color through to an attached client when it can
    # tell the client supports RGB — normally via COLORTERM, which incus exec
    # does not forward. Force the RGB feature for xterm-256color clients so
    # the nord theme renders truecolor on the attached terminal (konsole).
    set -as terminal-features ",xterm-256color:RGB"
  '';

  # Tool selection is config-only in coi (there is no --tool flag). coi seeds
  # ~/.config/opencode/{opencode.json,tui.json} into the container on its own
  # (they are part of its credential catalog) — the home-manager-managed
  # versions on this host carry over automatically.
  home.file.".coi/config.toml".text = ''
    [container]
    # Keep the session container alive across exits: fresh containers write
    # ~300 MB of tool-bootstrap data (mise runtimes, claude, opencode's TUI
    # engine) and take ~2 minutes to become usable; persistent containers are
    # reused warm and start in seconds. `coi kill` (or `coi clean`) removes
    # them when a project is done.
    persistent = true

    [tool]
    name = "opencode"
    # permission_mode = "interactive"  # default "bypass" injects "permission": {"*": "allow"}

    [monitoring]
    # Real-time threat detection (reverse shells, data exfiltration, credential
    # access, nftables network events). Thresholds stay at coi's defaults.
    # auto_pause_on_high is disabled: a fresh container legitimately writes
    # ~300 MB of tool-bootstrap I/O (mise runtimes, claude, opencode's TUI
    # engine) within the detector's 50 MB/2s window, so HIGH bulk-write
    # events fired on every first session and auto-paused the TUI mid-boot
    # (the frozen unstyled splash). Detection and audit logging stay fully
    # active, and CRITICAL threats still auto-kill the container.
    enabled = true
    auto_pause_on_high = false

    [defaults]
    # Forward the color-capability marker so the TUI renders the nord theme
    # as on the host (without it the sandbox falls back to 256 colors).
    forward_env = [ "COLORTERM" ]

    [defaults.env_commands]
    # coi redirects XDG_DATA_HOME into the workspace so opencode's session db
    # persists — but that also hides the mise runtimes the coi image already
    # installed, making mise re-download them on every session (the write
    # bursts tripped the monitoring auto-pause). Point mise at its image-level
    # data dir explicitly; MISE_DATA_DIR takes precedence over XDG_DATA_HOME.
    MISE_DATA_DIR = "echo /home/code/.local/share/mise"
    # coi starts the tool inside a DETACHED tmux session and attaches only
    # afterwards. The TUI probes the terminal's color capabilities at
    # startup, tmux reports none (no attached client), and it renders
    # permanently unstyled — the "theme is not applied" effect. FORCE_COLOR=3
    # (supports-color convention: 3 = 24-bit) forces truecolor output;
    # verified against the emitted escape sequences.
    FORCE_COLOR = "echo 3"

    # Read-only mounts of the home-manager-managed opencode config that coi
    # does not seed itself. Skills are real files (opencode-managed) so the
    # directory mounts as-is; AGENTS.md and the GLM plugin are Nix store
    # symlinks, so their resolved targets are mounted (see the let bindings).
    # Readonly mounts whose source is missing are skipped with a warning.

    [[mounts]]
    host = "${agentsMd}"
    container = "/home/code/.config/opencode/AGENTS.md"
    readonly = true

    [[mounts]]
    host = "${tuiJson}"
    container = "/home/code/.config/opencode/tui.json"
    readonly = true

    [[mounts]]
    host = "${glmPlugin}"
    container = "/home/code/.config/opencode/plugins/mistral-glm-model.ts"
    readonly = true

    [[mounts]]
    host = "~/.config/opencode/skills"
    container = "/home/code/.config/opencode/skills"
    readonly = true

    # tmux configuration read by the tmux server coi starts inside the
    # container (see the .coi/tmux.conf comment above).
    [[mounts]]
    host = "${config.home.file.".coi/tmux.conf".source}"
    container = "/home/code/.tmux.conf"
    readonly = true

    # The seeded opencode.json references the scaleway API key via a
    # {file:...} sops-nix path. opencode treats a missing referenced file as
    # a FATAL config error, so mount the secret read-only at the exact same
    # path inside the container. Both sides reference the same sops option
    # the opencode.json generation uses, so the paths cannot drift.
    [[mounts]]
    host = "${config.sops.secrets.scaleway_key.path}"
    container = "${config.sops.secrets.scaleway_key.path}"
    readonly = true

    # opencode authentication. coi redirects XDG_DATA_HOME into the workspace
    # (<project>/.local/share) so the sandbox's own session history survives
    # container recreation; the host auth.json is copied there every session.
    # NOTE: run once per project BEFORE its first `coi shell` (coi creates
    # missing parent directories as container root — an upstream bug, see the
    # drafted issue — leaving them unwritable for the sandbox user):
    #   mkdir -p .local/share/opencode
    # and keep ".local/" in the project's .gitignore.
    [[credentials]]
    host = "~/.local/share/opencode/auth.json"
    container = "/workspace/.local/share/opencode/auth.json"
    mode = "0600"
  '';
}
