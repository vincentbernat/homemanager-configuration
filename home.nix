{ config, pkgs, lib, flakes, ... }:

{
  programs.home-manager.enable = true;

  home = {
    username = "bernat";
    homeDirectory = "/home/bernat";
    stateVersion = "20.09";

    packages =
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
          inherit (pkgs.thunderbird-esr-bin-unwrapped) version src;
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
          alsaSupport = false;
          pulseSupport = false;
          nlSupport = false;
        }).overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/polybar-i3sock.patch
            (pkgs.fetchpatch {
              url = "https://github.com/polybar/polybar/pull/3159.diff";
              hash = "sha256-VWNtsplxvZE2D8MN7mC1ltzHSYnkqCHM52fzLOo1KaA=";
            })
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
      in
      with pkgs; [
        bat
        difftastic
        direnv
        docker-client
        doggo
        firefox
        thunderbird
        gh
        glibcLocales
        less
        mergiraf
        tmux
        uv
        yt-dlp
        flakes.vbeterm.packages.${system}.default
        # Cannot add:
        # - xsecurelock (uses PAM)
      ] ++ [
        # IA stuff
        claude-code
        gemini-cli
        opencode
      ] ++ [
        # Emacs-related
        nodePackages.prettier
        eslint
        yaml-language-server
        beancount-language-server
        typescript-language-server
        vue-language-server
        nixd # (Nix LSP)
        gopls # (Go LSP)
        ruff # (Python linter)
      ] ++ [
        # Nix-related
        nix
        nix-zsh-completions
        nixpkgs-fmt
        nix-direnv
      ] ++ [
        # i3-related
        dragon-drop
        dunst
        i3
        polybar
        xssproxy
      ] ++ [
        # Pipewire
        pipewire
        wireplumber
        pavucontrol
        easyeffects
      ];

    file =
      let
        tree-sitter-languages =
          let
            langs = [
              "c"
              "clojure"
              "cpp"
              "css"
              "dockerfile"
              "go"
              "gomod"
              "gowork"
              "java"
              "javascript"
              "jsdoc"
              "json"
              "lua"
              "nix"
              "python"
              "rust"
              "typescript"
              "vue"
              "yaml"
              "yang"
            ];
          in
          pkgs.runCommand "tree-sitter-languages" { } ''
            mkdir -p $out
            ${lib.concatMapStringsSep "\n" (lang: ''
              cp ${pkgs.tree-sitter-grammars."tree-sitter-${lang}"}/parser $out/libtree-sitter-${lang}.so
            '') langs}
          '';
      in
      {
        ".config/doom/tree-sitter~".source = tree-sitter-languages;
      };

    activation = {
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
  };
}
