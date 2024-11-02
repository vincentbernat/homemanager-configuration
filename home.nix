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
      glibcLocales = pkgs.glibcLocales.override {
        allLocales = false;
        locales = [ "en_US.UTF-8/UTF-8" "fr_FR.UTF-8/UTF-8" "C.UTF-8/UTF-8" ];
      };
      i3 = pkgs.i3.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          # Mouse wheel should focus windows too
          ./patches/i3-more-mouse-buttons.patch
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
        patches = (old.patches or [ ]) ++ [
          ./patches/polybar-i3sock.patch
        ];
      });
      direnv = pkgs.direnv.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url = "https://github.com/direnv/direnv/pull/1010.patch";
            hash = "sha256-UFugO+U/+bdkyL01KFBWuN4KQUWBjN4eVbpc1DW0iFI=";
          })
        ];
      });
      pipewire = pkgs.pipewire.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url = "https://gitlab.freedesktop.org/pipewire/pipewire/-/merge_requests/2149.patch";
            hash = "sha256-bwHaDBFdNFb/42/PrUavrsMxirNBT1PUcdJHYPoXSxo=";
          })
        ];
      });
      less = pkgs.less.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "gwsw";
          repo = "less";
          rev = "56fb53f2e15ad5fe58577b9fc7b99de0e3b33318";
          hash = "sha256-ry+7xNljNK7r1cZXLQf/8hY7QYMz2tWpu0H42CzJ0BQ=";
        };
        preConfigure = (old.preConfigure or "") + ''
          patchShebangs ./mkhelp.pl
          make -f Makefile.aut distfiles
        '';
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ (with pkgs; [
          perl
          autoreconfHook
          groff
        ]);
      });
      caddy =
        let
          plugins = [{ module = "github.com/caddy-dns/powerdns"; version = "1.0.1"; }];
        in
        pkgs.caddy.overrideAttrs (old: {
          vendorHash = "sha256-SOmuWosm29m2JtCTE2yIb/d2MQ7meJG859C+4cMalzM=";
          proxyVendor = true;
          # prePatch is executed twice: once to build the vendor directory and
          # go.sum is updated and once for the final build where go.sum is not
          # updated (no network access). So, we put it as part of the goModules
          # derivation and retrieve it. We also run "go mod tidy" during the
          # build of goModules as "go mod download" does not add hash of
          # modules, just hash of go.mod.
          prePatch =
            let
              imports = lib.concatMapStrings (plugin: "       _ \"${plugin.module}\"\\\n") plugins;
              requires = lib.concatMapStrings (plugin: "    ${plugin.module} v${plugin.version}") plugins;
            in
            ''
              # Add plugins to main.go
              sed -i '/plug in Caddy modules here/a\
              ${imports}' cmd/caddy/main.go

              # Add plugins to go.mod
              sed -i '/require (/a\
              ${requires}' go.mod

              [ -z "''${goModules}" ] || \
                cp "''${goModules}/go.mod" "''${goModules}/go.sum" .
            '';
          modPostBuild = ''
            go mod tidy
            cp go.mod go.sum "''${GOPATH}/pkg/mod/cache/download/."
          '';
        });
    in
    with pkgs; [
      bat
      caddy
      difftastic
      direnv
      docker
      doggo
      firefox
      thunderbird
      glibcLocales
      less
      tmux
      yt-dlp
      flakes.vbeterm.packages.${system}.default
      # Cannot add:
      # - xsecurelock (uses PAM)
    ] ++ [
      # Emacs-related
      nodePackages.prettier
      eslint
      yaml-language-server
      beancount-language-server
      nixd # (Nix LSP)
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
      pavucontrol
    ];

  home.activation = {
    diff = lib.hm.dag.entryBefore [ "installPackages" ] ''
      [[ -z "''${oldGenPath:-}" ]] || [[ "$oldGenPath" = "$newGenPath" ]] || \
         ${pkgs.nvd}/bin/nvd diff "$oldGenPath" "$newGenPath"
    '';
    browserpass =
      let
        browserpass = pkgs.browserpass.override {
          gnupg = null;
        };
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ln -sf $VERBOSE_ARG \
          ${browserpass}/lib/mozilla/native-messaging-hosts/com.github.browserpass.native.json \
          ~/.mozilla/native-messaging-hosts/.
      '';
  };
}
