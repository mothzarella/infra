{
  aspects.xdg = {
    nixos.nix.settings.use-xdg-base-directories = true;

    nixos.environment.sessionVariables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_BIN_HOME = "$HOME/.local/bin";

      HISTFILE = "$HOME/.local/state/bash/history";
      GIT_CONFIG_GLOBAL = "$HOME/.config/git/config";
      ABDUCO_SOCKET_DIR = "$XDG_RUNTIME_DIR";
      CLAUDE_CONFIG_DIR = "$HOME/.config/claude";
    };

    user = {
      config,
      lib,
      pkgs,
      ...
    }: {
      options.mimeApps = lib.mkOption {
        type = with lib.types; attrsOf (coercedTo str lib.toList (listOf str));
        default = {};
      };

      config = {
        files.".config/mimeapps.list" = (pkgs.formats.ini {listToValue = l: lib.concatStrings (map (v: "${v};") l);}).generate "mimeapps.list" {
          "Default Applications" = config.mimeApps;
        };

        files.".config/user-dirs.dirs" = pkgs.writeText "user-dirs.dirs" (
          lib.generators.toKeyValue {} (lib.mapAttrs' (k: v: lib.nameValuePair "XDG_${k}_DIR" ''"$HOME/${v}"'') {
            DESKTOP = ""; # unset dirs fall back to ~
            DOCUMENTS = "Documents";
            DOWNLOAD = "Downloads";
            PICTURES = "Pictures";
          })
        );

        files.".config/user-dirs.conf" = pkgs.writeText "user-dirs.conf" "enabled=False\n";

        packages = [
          pkgs.handlr-regex
          (pkgs.writeShellScriptBin "xdg-open" ''exec ${lib.getExe pkgs.handlr-regex} open "$@"'')
        ];
      };
    };
  };
}
