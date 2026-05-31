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
            # claude-code 2.1.156
            (pkgs.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/pull/525449.patch";
              hash = "sha256-m6JNi73wgDmxkXUusSMvMpa0YEy3DhgqcDd6wuosqHA=";
            })
            # claude-code 2.1.158
            (pkgs.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/pull/525909.patch";
              hash = "sha256-dTpKU3QF1bl8WTUJO5eGyLiLeY78Yv8N4LmL8OA8WhQ=";
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
