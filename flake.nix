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
            # claude-code 2.1.111
            (pkgs.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/pull/510655.patch";
              hash = "sha256-1SnvLrQrEZO1yJ/v+q54ZCxhZXT0ZreqTgZ9BiFsMQ4=";
            })
            # claude-code 2.1.112
            (pkgs.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/pull/510736.patch";
              hash = "sha256-Kal414T04hjDNth2JvsvEabhzeQ4fl+8N8omNw5FWcU=";
            })
            # claude-code 2.1.114
            (pkgs.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/pull/511117.patch";
              hash = "sha256-dm8oXIWNTu94TST0UU/TMl88Qwizqldhu4s/TJBAE5A=";
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
