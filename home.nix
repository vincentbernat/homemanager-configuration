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
        # Host in ssh -G
        (pkgs.fetchpatch {
          url = "https://bugzilla.mindrot.org/attachment.cgi?id=3547";
          sha256 = "sha256-uF+pPRlO9UmavjqQox6RRGFKYrmxbqygXMr1Tx7J3mA=";
        })
      ];
    });
    dunst = pkgs.dunst.overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        # icon scaling
        (pkgs.fetchpatch {
          url = "https://github.com/dunst-project/dunst/pull/1070.patch";
          sha256 = "sha256-1XGQ51hmlwN5RyA96I6fv7BRFkkjXg4djbUO18744xY=";
        })
      ];
    });
    i3 = pkgs.i3-gaps.overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        # move to output next|prev
        (pkgs.fetchpatch {
          url = "https://github.com/i3/i3/pull/4622.patch";
          sha256 = "sha256-V/Pq5FtM+fM+pOqco48cB88r9/VZrM3daYnxkC8sfpE=";
        })
        # Mouse wheel should focus windows too
        (pkgs.fetchpatch {
          url = "https://github.com/vincentbernat/i3/commit/1ba57fd0256f184648c3e10d2523df08b0cc6f5b.patch";
          sha256 = "sha256-QTEX3Wza3QG+rVqVeaKJCKizTx9VNLNBy51K91xDkB8=";
        })
      ];
    });
  in
    with pkgs; [
      bat
      dunst
      (emacs.override {
        nativeComp = true;
      })
      (glibcLocales.override {
        allLocales = false;
        locales = ["en_US.UTF-8/UTF-8" "fr_FR.UTF-8/UTF-8" "C.UTF-8/UTF-8"];
      })
      i3
      maim
      mp4v2
      nix
      nix-zsh-completions
      nixpkgs-fmt
      openssh
      yarn
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
