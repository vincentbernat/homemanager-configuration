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
        installPhase = ''
          # Disable auto updates
          mkdir -p distribution
          echo '{"policies": {"AppAutoUpdate": false, "ManualAppUpdateOnly": true}}' >> distribution/policies.json

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
        inherit (pkgs.thunderbird-bin-unwrapped) version src;
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
      glibcLocales = pkgs.glibcLocales.override {
        allLocales = false;
        locales = [ "en_US.UTF-8/UTF-8" "fr_FR.UTF-8/UTF-8" "C.UTF-8/UTF-8" ];
      };
      i3 = pkgs.i3.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          # Mouse wheel should focus windows too
          (pkgs.fetchpatch {
            url = "https://github.com/vincentbernat/i3/commit/1ba57fd0256f184648c3e10d2523df08b0cc6f5b.patch";
            hash = "sha256-QTEX3Wza3QG+rVqVeaKJCKizTx9VNLNBy51K91xDkB8=";
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
      direnv = pkgs.direnv.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url = "https://github.com/direnv/direnv/pull/1010.patch";
            hash = "sha256-702FM1GghJOxN5i+VnDdq91ATv78+lMiBC2lg1mh5z0=";
          })
        ];
      });
      tmux = pkgs.tmux.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url = "https://github.com/tmux/tmux/pull/3319.patch";
            hash = "sha256-Nq5Oe0vL4wM8aC8O086JgIl+Zamfb4MByUm8JUef11Y=";
          })
        ];
      });
    in
    with pkgs; [
      bat
      difftastic
      direnv
      docker
      doggo
      firefox
      thunderbird
      glibcLocales
      jless
      tmux
      yarn
      yt-dlp
      flakes.vbeterm.packages.${system}.default
      # Cannot add:
      # - xsecurelock (uses PAM)
    ] ++ [
      # Emacs-related
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
      wireplumber
    ];

  home.activation = {
    diff = lib.hm.dag.entryBefore [ "installPackages" ] ''
      [[ -z "''${oldGenPath:-}" ]] || [[ "$oldGenPath" = "$newGenPath" ]] || \
         ${pkgs.nvd}/bin/nvd diff "$oldGenPath" "$newGenPath"
    '';
    browserpass = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ln -sf $VERBOSE_ARG \
        ${pkgs.browserpass}/lib/mozilla/native-messaging-hosts/com.github.browserpass.native.json \
        ~/.mozilla/native-messaging-hosts/.
    '';
  };
}
