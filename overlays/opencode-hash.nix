# Fix opencode 2.2.5 node_modules hash mismatch on nixos-unstable @ 1d06008.
# https://github.com/NixOS/nixpkgs/issues/582673
# https://github.com/NixOS/nixpkgs/pull/582675
#
# The 2.2.5 bump pinned the node_modules hash computed with bun 1.4.2, but
# bun 1.4.4 (merged hours later) filters optional dependencies by host libc,
# so the pinned hash matches no platform. The value below is the Linux
# output, the same one #582675 ships — drop this overlay once the
# nixos-unstable channel carries that commit.
final: prev:
{
  opencode =
    if prev.opencode.version == "2.2.5" then
      prev.opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs {
          outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
        };
      })
    else
      prev.opencode;
}
