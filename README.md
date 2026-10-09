# NixOS (Lix) dotfiles

My declarative, reproducible [NixOS](https://nixos.org/) system built using [Lix](https://lix.systems/). My configuration is designed to support the following:

- Multiple hosts, including an Apple Silicon MacBook (mine has a M2 Max chip) and an Apple Silicon Mac Mini ;
- Multiple users, some of whom are reused across different hosts ;
- Variants of users ;
- A beautiful KDE Plasma desktop with [theme Nord](https://www.nordtheme.com/) applied everywhere ;
- LibreWolf which I spent some time hardening ;
- My Emacs config including OpenCode.el ;
- Shell synchronisation via `atuin` ;
- LUKS encryption via `disko` ;
- Secrets management with `sops`.

I've aimed for a balance between readability and completeness.

## Installation

Please follow my installation instructions in [INSTALL.md](INSTALL.md).

If you set up a new machine you should probably [generate](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) a new SSH key pair. Put your keys in `/home/thomas/.ssh/` once you're logged in in your new machine. Don't forget to set up a new password for your user using `passwd`.

Put your `age` keys here:

```console
vim /home/thomas/.config/sops/age/keys.txt
```

Now you are ready to clone this configuration. Update my user `thomas` with yours. Once you are ready, rebuild the system:

```console
nixos-rebuild switch --flake .#host --sudo

# Or, better
nh os switch . -H host
```

To rebuild a remote system locally, and deploy it:

```console
nixos-rebuild switch --flake .#golmotte --target-host thomas@golmotte --sudo

# Or, better
nh os switch . -H golmotte --target-host thomas@golmotte
```

If you run out of memory, add parameters `--cores x` and `--max-jobs x` to the build command.

## Available hosts

This configuration supports multiple hosts as documented in [`hosts/README.md`](hosts/README.md).

## Manual configuration

Some packages require manual configuration.

### Atuin

If you imported `age` keys, just login to retrieve your shell history:

```console
atuin login
atuin sync
```

### Obsidian

Just open Obsidian, login and sync everything including community plugins and settings (`Active community plugin list` and `Installed community plugins` options). Wait for the end of the synchronization, and restart the app.

### OpenCode

If running OpenCode from outside Emacs, use the following command to connect to the local server:

```console
opencode attach http://localhost:4096
```

### Tailscale

Connect your machine to your Tailscale network and authenticate in your browser:

```console
sudo tailscale up
```

In Dolphin (or somewhere else), use `smb://user@ip` to connect to a remote SMB share.

### Printers

You can add a printer from the KDE settings > `Define a connection to a printer` > `PDD file` (you should see something like `canonts3500.ppd`).

## Useful commands

Optimize the Nix store by hard linking duplicate binaries. This shouldn't be needed with my current dotfiles though, as optimizations are performed automatically at build time.

```console
nix-store --optimise
```

The Nix store accumulates entries which are no longer useful. They can be deleted:

```console
nix-store --gc
```

Delete all generations older than a specific period (e.g. 30 days):

```console
nix-collect-garbage --delete-older-than 30d
```

These commands are run altogether when using:

```console
nh clean all --keep-since 30d
```

## Future work

Limitations:

- (localsend) Fonts are not rendering under Asahi Linux https://github.com/localsend/localsend/issues/2873. A temporary overlay fixes this issue.
- (dns4eu) I should find a way to enable DNSOverTLS with DNS4EU.
- (librewolf) `privacy.resistFingerprinting = true` prevents media upload and Leboncoin login from working.
- (vscodium) VSCodium 1.126 ignores `ELECTRON_RUN_AS_NODE`, so the marimo extension's bundled WASM language server (spawned via Electron-as-Node) never starts and crashes in a `-32097` loop. Workaround in `users/thomas/vscode.nix`: run the extension's `wasmServer.js` with Nixpkgs' Node (`marimo.lsp.server = "custom"`). Once VSCodium honors the variable again — check with `ELECTRON_RUN_AS_NODE=1 codium --version`, which should print a Node version — remove the workaround.

These are not fully integrated yet:

- SDDM doesn't offer a keyboard layout selection, which is very annoying for non-US keyboard users. SDDM should be incubated into Plasma [at some point](https://invent.kde.org/plasma/plasma-desktop/-/issues/91).

## Some resources I found useful

- [Introduction to Nix and NixOS](https://www.youtube.com/watch?v=QKoQ1gKJY5A&list=PL-saUBvIJzOkjAw_vOac75v-x6EzNzZq-) by Wil T
- I got some inspiration from [geraldwuhoo](https://github.com/geraldwuhoo/nixos-config)
- [NixOS Secrets Management](https://www.youtube.com/watch?v=6EMNHDOY-wo) by EmergentMind
- [Flakes + Home Manager Multiuser/Multihost Configuration](https://www.youtube.com/watch?v=e8vzW5Y8Gzg) by Chris McDonough
- [NixOS on Apple Silicon](https://yusef.napora.org/blog/nixos-asahi/) by sef
- [Moving the store](https://nixos.wiki/wiki/Storage_optimization#Moving_the_store)
