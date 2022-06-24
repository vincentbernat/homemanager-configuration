{ config, pkgs, lib, ... }:

{
  programs.home-manager.enable = true;

  home.username = "bernat";
  home.homeDirectory = "/home/bernat";
  home.stateVersion = "20.09";

  home.packages =
    let
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
        version = "102.0";
        src = pkgs.fetchurl {
          url = "http://archive.mozilla.org/pub/firefox/candidates/${version}-candidates/build2/linux-x86_64/en-US/firefox-${version}.tar.bz2";
          sha256 = "sha256-JnPTh9Iq5uIcIPCR3EgRGXqqUWEQ1EEz5NFMkdVWj4c=";
        };
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
        version = "102.0b8";
        src = pkgs.fetchurl {
          url = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/${version}/linux-x86_64/en-US/thunderbird-${version}.tar.bz2";
          sha256 = "sha256-r1XGPBCLawQNiUlzl9C8m3tlQ1gH/Qv8N5kIcgeVzII=";
        };
        genericName = "Mail Client";
        mimeTypes = [
          "message/rfc822"
          "x-scheme-handler/mailto"
          "text/calendar"
          "text/x-vcard"
        ];
      };
      dunst = pkgs.dunst.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          # offset uses DPI
          (pkgs.fetchpatch {
            url = "https://github.com/dunst-project/dunst/commit/0a86f0940a5c673648fd87d5dd7d621fac4935af.patch";
            sha256 = "sha256-caL/ZcQHhUmhZRf7g1YsDU96Eiwlfn2tIIhpD8ml4Yw=";
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
      pipewire = pkgs.pipewire.overrideAttrs (old: rec {
        version = "0.3.52";
        src = pkgs.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "pipewire";
          repo = "pipewire";
          rev = version;
          sha256 = "sha256-JWmO36+OF2O9sLB+Z0znwm3TH+O+pEv3cXnuwP6Wy1E=";
        };
        patches = (old.patches or [ ]) ++ [
          # Only use 48 kHz sample rate
          (pkgs.fetchpatch {
            url = "https://gitlab.freedesktop.org/pipewire/pipewire/-/commit/16a7c274989f47b0c0d8ba192a30316b545bd26a.patch";
            sha256 = "sha256-VZ7ChjcR/PGfmH2DmLxfIhd3mj9668l9zLO4k2KBoqg=";
          })
        ];
        mesonFlags = old.mesonFlags ++ [
          "-Dbluez5-codec-lc3plus=disabled"
        ];
      });
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
      dogdns
      emacs
      firefox
      thunderbird
      glibcLocales
      mp4v2
      openssh
      yarn
      yt-dlp
    ] ++ [
      # Nix-related
      nix
      nix-zsh-completions
      nixpkgs-fmt
    ] ++ [
      # i3-related
      dunst
      i3
      maim
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

# To install:
#  - check where nix command is installed (readlink -f =nix)
#  - remove everything from nix-env (nix-env -u)
#  - install with PATH=/nix/store/...:$PATH nix-shell '<home-manager>' -A install
