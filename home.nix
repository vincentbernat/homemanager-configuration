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
      firefox-or-thunderbird = which: pkgs.stdenvNoCC.mkDerivation {
        inherit (which) pname version src;
        desktopItem = pkgs.makeDesktopItem rec {
          inherit (which) genericName mimeTypes;
          name = which.pname;
          exec = "${which.pname} %U";
          desktopName = (lib.toUpper (lib.substring 0 1 which.pname) + lib.substring 1 (-1) which.pname);
          icon = which.pname;
          startupWMClass = desktopName;
          startupNotify = true;
        };
        patchPhase = ''
          # Don't download updates from Mozilla directly
          echo 'pref("app.update.auto", "false");' >> defaults/pref/channel-prefs.js
        '';
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
      thunderbird = (firefox-or-thunderbird rec {
        pname = "thunderbird";
        version = "109.0b2";
        src = pkgs.fetchurl {
          url = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/${version}/linux-x86_64/en-US/thunderbird-${version}.tar.bz2";
          hash = "sha256-1PdXnA8XrCGf15U/HsW17jJaER3LzE9kltymmKkhJlY=";
        };
        genericName = "Mail Client";
        mimeTypes = [
          "message/rfc822"
          "x-scheme-handler/mailto"
          "text/calendar"
          "text/x-vcard"
        ];
      }).overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./patches/thunderbird-identities.patch
        ];
        prePatch = ''
          ${pkgs.unzip}/bin/unzip -d omni omni.ja
        '';
        postPatch = ''
          cd omni
          ${pkgs.zip}/bin/zip -0DXqr ../omni.ja *
          cd ..
          rm -rf omni
        '';
      });
      xssproxy = pkgs.xssproxy.overrideAttrs (old: rec {
        version = "1.1.0";
        src = pkgs.fetchFromGitHub {
          owner = "vincentbernat";
          repo = "xssproxy";
          rev = "v${version}";
          hash = "sha256-BE/v1CJAwKwxlK3Xg3ezD+IXyT7ZFGz3bQzGxFQfEnU=";
        };
      });
      openssh = pkgs.openssh.overrideAttrs (old: {
        checkTarget = [ ];
        patches = (old.patches or [ ]) ++ [
          # Host in ssh -G
          (pkgs.fetchpatch {
            url = "https://bugzilla.mindrot.org/attachment.cgi?id=3547";
            hash = "sha256-uF+pPRlO9UmavjqQox6RRGFKYrmxbqygXMr1Tx7J3mA=";
          })
        ];
      });
      glibcLocales = pkgs.glibcLocales.override {
        allLocales = false;
        locales = [ "en_US.UTF-8/UTF-8" "fr_FR.UTF-8/UTF-8" "C.UTF-8/UTF-8" ];
      };
      i3 = pkgs.i3.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "i3";
          repo = "i3";
          rev = "96614a2f32ae5f0a8f39e49d98a4d2183a379516";
          hash = "sha256-zd/PPmXR/PknWDwFWCktLtolo7UnUnG+v7GZ6NnQw/s=";
        };
        patches = (old.patches or [ ]) ++ [
          # Mouse wheel should focus windows too
          (pkgs.fetchpatch {
            url = "https://github.com/vincentbernat/i3/commit/1ba57fd0256f184648c3e10d2523df08b0cc6f5b.patch";
            hash = "sha256-QTEX3Wza3QG+rVqVeaKJCKizTx9VNLNBy51K91xDkB8=";
          })
        ];
      });
      direnv = pkgs.direnv.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url = "https://github.com/direnv/direnv/pull/1010.patch";
            hash = "sha256-702FM1GghJOxN5i+VnDdq91ATv78+lMiBC2lg1mh5z0=";
          })
        ];
      });
      polybar = (pkgs.polybar.override {
        inherit i3;
        i3Support = true;
        pulseSupport = true;
      }).overrideAttrs (old: {
        version = "3.6.3";
        src = pkgs.fetchFromGitHub {
          owner = "vincentbernat";
          repo = "polybar";
          rev = "6464e4670ac0"; # vbe/master
          fetchSubmodules = true;
          hash = "sha256-lbl4VYOk7bVOuTt0JV9UbgmEFBx4IRHgz9eZM7ibw98=";
        };
      });
      emacs = pkgs.emacs.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            # Fix detection of DPI change in builds without Xft
            url = "https://github.com/emacs-mirror/emacs/commit/52d4c98cec0901ef5cc1c55d5b3b33ac9d9c519f.patch";
            hash = "sha256-KkpFgibyZmrrl9iggI8AsaieLx7hVsZtXE1BZNG6zeA=";
          })
          (pkgs.fetchpatch {
            # Allow NUL in JSON input
            url = "https://github.com/emacs-mirror/emacs/commit/8b52d9f5f177ce76b9ebecadd70c6dbbf07a20c6.patch";
            hash = "sha256-/W9yateE9UZ9a8CUjavQw0X7TgxigYzBuOvtAXdEsSA=";
          })
        ];
      });
    in
    with pkgs; [
      bat
      difftastic
      direnv
      docker
      dogdns
      firefox
      thunderbird
      glibcLocales
      jless
      openssh
      yarn
      yt-dlp
      flakes.vbeterm.packages."${system}".default
      # Cannot add:
      # - xsecurelock (uses PAM)
    ] ++ [
      # Emacs-related
      emacs
      nodePackages.prettier
      nodePackages.eslint
      yaml-language-server
      nil # (Nix LSP)
    ] ++ [
      # Nix-related
      nix
      nix-zsh-completions
      nixpkgs-fmt
      nix-direnv
    ] ++ [
      # i3-related
      dunst
      i3
      polybar
      xssproxy
      xdragon
    ] ++ [
      # Pipewire
      pipewire
      pipewire.pulse
      wireplumber
    ];

  home.activation.diff = lib.hm.dag.entryBefore [ "installPackages" ] ''
    [[ -z "''${oldGenPath:-}" ]] || [[ "$oldGenPath" = "$newGenPath" ]] || \
       ${pkgs.nvd}/bin/nvd diff "$oldGenPath" "$newGenPath"
  '';
}
