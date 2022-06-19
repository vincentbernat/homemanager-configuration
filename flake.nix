{
  description = "Home manager flake";
  inputs = {
    nixpkgs.url = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      username = "bernat";
    in
    {
      homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
        inherit system pkgs username;
        homeDirectory = "/home/${username}";
        configuration = import ./home.nix;
      };
    };
}
