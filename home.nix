{ config, pkgs, lib, ... }:

{
  programs.home-manager.enable = true;

  home.username = "bernat";
  home.homeDirectory = "/home/bernat";
  home.stateVersion = "20.09";

  home.packages = let
    openssh = pkgs.openssh.overrideAttrs (old: {
      checkTarget = [];
      patches = (old.patches or []) ++ [
        (pkgs.fetchpatch {
          url = "https://bugzilla.mindrot.org/attachment.cgi?id=3547";
          sha256 = "sha256-uF+pPRlO9UmavjqQox6RRGFKYrmxbqygXMr1Tx7J3mA=";
        })
      ];
    });
  in
    with pkgs; [
      bat
      (glibcLocales.override {
        allLocales = false;
        locales = ["en_US.UTF-8/UTF-8" "fr_FR.UTF-8/UTF-8" "C.UTF-8/UTF-8"];
      })
      i3-gaps
      mp4v2
      nix
      nix-zsh-completions
      nixpkgs-fmt
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
