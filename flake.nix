{
  description = "Home manager flake";
  inputs = {
    nixpkgs.url = "nixpkgs";
    home-manager = {
      url = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vbeterm = {
      url = "github:vincentbernat/vbeterm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ... }@inputs:
    let
      pkgs = (import nixpkgs {
        system = "x86_64-linux";
      });
      pkgs-patched = import
        (pkgs.applyPatches {
          name = "nixpkgs-patched";
          src = pkgs.path;
          patches = ([
            # claude-code 2.1.118
            (pkgs.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/pull/512648.patch";
              hash = "sha256-WViggOrt5DKSFOpYZLTPLpHS2iYKp8Fc2c7VxHVzP6A=";
            })
          ]);
        })
        {
          inherit (pkgs.stdenv) system;
          config = {
            allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
              "claude-code"
            ];
          };
        };
    in
    {
      homeConfigurations.bernat = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs-patched;
        modules = [ ./home.nix ];
        extraSpecialArgs = { flakes = inputs; };
      };
    };
}
