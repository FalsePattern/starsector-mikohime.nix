This flake is a nixos port of the Mikohime starsector java 23 mod.

Thread: https://fractalsoftworks.com/forum/index.php?topic=29320.0

To run this, you can either:
- Run `NIXPKGS_ALLOW_UNFREE=1 nix run .#starsector --impure`
- Pull it into your system flake, `starsector` package exposed by this flake (you can look at other flakes for how to do that)

The `starsector` binary wrapper will automatically copy the mods that ship with Mikohime into `~/.local/share/starsector/mods`
