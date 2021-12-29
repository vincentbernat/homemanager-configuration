{ config, pkgs, lib, ... }:

{
  programs.home-manager.enable = true;

  home.username = "bernat";
  home.homeDirectory = "/home/bernat";
  home.stateVersion = "21.05";

  home.packages = with pkgs; [
    bat
    glibcLocales
    mp4v2
    nix
    nix-zsh-completions
    openssh
    yt-dlp
  ];

  home.activation.diff = lib.hm.dag.entryBefore ["installPackages"] ''
    nix store diff-closures "$oldGenPath" "$newGenPath"
  '';
}

  # To install:
  #  - check where nix command is installed (readlink -f =nix)
  #  - remove everything from nix-env (nix-env -u)
  #  - install with PATH=/nix/store/...:$PATH nix-shell '<home-manager>' -A install
