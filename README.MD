This flake is a nixos port of the Mikohime starsector java 23 mod.

To run this, you can either:
- Run `NIXPKGS_ALLOW_UNFREE=1 nix run .#starsector --impure`
- Pull it into your system flake, `starsector` package exposed by this flake (you can look at other flakes for how to do that)
