{
  description = "Home manager flake";
  inputs = {
    nixpkgs.url = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    homeConfigurations = {
      bernat = inputs.home-manager.lib.homeManagerConfiguration rec {
        system = "x86_64-linux";
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        homeDirectory = "/home/bernat";
        username = "bernat";
        configuration = import ./home.nix;
      };
    };
  };
}
