{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    # System types to support.
    supportedSystems = [ "x86_64-linux" ];

    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for supported system types.
    nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

  in
  {

    overlay = self: super: {
      starsector = super.callPackage ./pkgs/starsector-mikohime.nix { };
    };

    packages = forAllSystems (system: {
      inherit (nixpkgsFor.${system}) starsector;
    });

    apps = forAllSystems (system:
      let
        pkgs = nixpkgsFor.${system};
      in {
        starsector = {
          type = "app";
          program = "${pkgs.starsector}/bin/starsector";
        };
      });
  };
}
