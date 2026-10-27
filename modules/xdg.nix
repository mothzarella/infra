{
  aspects.xdg = {
    nixos = {
      nix.settings.use-xdg-base-directories = true;

      environment.sessionVariables = {
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_STATE_HOME = "$HOME/.local/state";
        XDG_BIN_HOME = "$HOME/.local/bin";
        HISTFILE = "$HOME/.local/state/bash/history";
        GIT_CONFIG_GLOBAL = "$HOME/.config/git/config";

        GRADLE_USER_HOME = "$HOME/.cache/gradle";
        NPM_CONFIG_CACHE = "$HOME/.cache/npm";
        NUGET_PACKAGES = "$HOME/.cache/nuget/packages";
        NUGET_HTTP_CACHE_PATH = "$HOME/.cache/nuget/v3-cache";
        NUGET_PLUGINS_CACHE_PATH = "$HOME/.cache/nuget/plugins-cache";
      };
    };

    user =
      { lib, pkgs, ... }:
      {
        preserve.directories = [
          "Downloads"
          "Pictures"
          ".config/git"
          ".local/state/bash"
          ".cache/gradle"
          ".cache/npm"
          ".cache/nuget"
        ];

        files = {
          ".config/mimeapps.list" = "/etc/xdg/mimeapps.list";
          ".config/user-dirs.dirs" =
            {
              DESKTOP = ""; # fallback to ~
              DOCUMENTS = "Documents";
              DOWNLOAD = "Downloads";
              PICTURES = "Pictures";
            }
            |> lib.mapAttrs' (k: v: lib.nameValuePair "XDG_${k}_DIR" ''"$HOME/${v}"'')
            |> lib.generators.toKeyValue { }
            |> pkgs.writeText "user-dirs.dirs";

          ".config/user-dirs.conf" = pkgs.writeText "user-dirs.conf" "enabled=False\n";
        };

        packages = [
          pkgs.handlr-regex
          (pkgs.writeShellScriptBin "xdg-open" ''exec ${lib.getExe pkgs.handlr-regex} open "$@"'')
        ];
      };
  };
}
