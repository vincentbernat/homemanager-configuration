{ config, pkgs, lib, flakes, ... }:

{
  programs.home-manager.enable = true;

  home.username = "bernat";
  home.homeDirectory = "/home/bernat";
  home.stateVersion = "20.09";

  home.packages =
    let
      system = pkgs.stdenv.hostPlatform.system;
      # Firefox may not be up-to-date in Debian due to toolchain
      # issues. Nixpkgs is quicker.
      firefox-or-thunderbird = which: pkgs.stdenv.mkDerivation {
        inherit (which) pname version src;
        phases = [ "unpackPhase" "installPhase" ];
        desktopItem = pkgs.makeDesktopItem rec {
          inherit (which) genericName mimeTypes;
          name = which.pname;
          exec = "${which.pname} %U";
          desktopName = (lib.toUpper (lib.substring 0 1 which.pname) + lib.substring 1 (-1) which.pname);
          icon = which.pname;
          startupWMClass = desktopName;
          startupNotify = true;
        };
        installPhase = ''
          mkdir -p "$prefix/usr/lib/${which.pname}-bin-${which.version}"
          cp -r * "$prefix/usr/lib/${which.pname}-bin-${which.version}"

          mkdir -p "$out/bin"
          cat > "$out/bin/${which.pname}" <<EOF
          #!/bin/sh
          export MOZ_LEGACY_PROFILES=1
          exec "$prefix/usr/lib/${which.pname}-bin-${which.version}/${which.pname}" "\$@"
          EOF
          chmod +x "$out/bin/${which.pname}"
          ln -s "$out/usr/lib" "$out/lib"

          for res in 16 32 48 64 128; do
          mkdir -p "$out/share/icons/hicolor/''${res}x''${res}/apps"
          icon=$( find "$out/lib/" -name "default''${res}.png" )
             if [ -e "$icon" ]; then ln -s "$icon" "$out/share/icons/hicolor/''${res}x''${res}/apps/${which.pname}.png"
             fi
          done
          install -D -t $out/share/applications $desktopItem/share/applications/*
        '';
      };
      firefox = firefox-or-thunderbird rec {
        pname = "firefox";
        inherit (pkgs.firefox-bin-unwrapped) version src;
        genericName = "Web Browser";
        mimeTypes = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "application/vnd.mozilla.xul+xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/ftp"
        ];
      };
      thunderbird = firefox-or-thunderbird rec {
        pname = "thunderbird";
        version = "103.0b4";
        src = pkgs.fetchurl {
          url = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/${version}/linux-x86_64/en-US/thunderbird-${version}.tar.bz2";
          sha256 = "sha256-oGXvSBTzQwXUtH+QTSgSW3mdZSYPDWTmkhoed4BsDPo=";
        };
        genericName = "Mail Client";
        mimeTypes = [
          "message/rfc822"
          "x-scheme-handler/mailto"
          "text/calendar"
          "text/x-vcard"
        ];
      };
      xssproxy = pkgs.xssproxy.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          # Flush stdout on logging
          (pkgs.fetchpatch {
            url = "https://github.com/timakro/xssproxy/pull/1.patch";
            sha256 = "sha256-Quoa7ZvuSIGOX/2q6rX+JTx1DdOtR1KI5xJGUFb0OX4=";
          })
        ];
      });
      openssh = pkgs.openssh.overrideAttrs (old: {
        checkTarget = [ ];
        patches = (old.patches or [ ]) ++ [
          # Host in ssh -G
          (pkgs.fetchpatch {
            url = "https://bugzilla.mindrot.org/attachment.cgi?id=3547";
            sha256 = "sha256-uF+pPRlO9UmavjqQox6RRGFKYrmxbqygXMr1Tx7J3mA=";
          })
        ];
      });
      emacs = pkgs.emacs.override {
        nativeComp = true;
      };
      glibcLocales = pkgs.glibcLocales.override {
        allLocales = false;
        locales = [ "en_US.UTF-8/UTF-8" "fr_FR.UTF-8/UTF-8" "C.UTF-8/UTF-8" ];
      };
      i3 = pkgs.i3-gaps.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
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
      delta
      dogdns
      emacs
      firefox
      thunderbird
      glibcLocales
      mp4v2
      openssh
      yarn
      yt-dlp
      flakes.vbeterm.packages."${system}".default
      # Cannot add:
      # - xsecurelock (uses PAM)
      # - polybar (???)
    ] ++ [
      # Nix-related
      nix
      nix-zsh-completions
      nixpkgs-fmt
    ] ++ [
      # i3-related
      dunst
      i3
      xssproxy
    ] ++ [
      # Pipewire
      pipewire
      pipewire.pulse
      wireplumber
    ];

  home.activation.diff = lib.hm.dag.entryBefore [ "installPackages" ] ''
    nix store diff-closures "$oldGenPath" "$newGenPath"
  '';
}
