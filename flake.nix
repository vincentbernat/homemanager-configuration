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
            # claude-code 2.1.218
            (pkgs.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/pull/544776.patch";
              hash = "sha256-B8y3MhgfY1LgAjMFwfJrEwN/WI83COX3nF+U91jyTeE=";
            })
            # claude-code 2.1.219
            (pkgs.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/pull/545319.patch";
              hash = "sha256-R6iIduRCu+VVAJyiHK8nukQk70OcLn8vLPlGquY8iMg=";
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
