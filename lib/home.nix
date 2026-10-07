# https://codeberg.org/viperML/nix-maid/src/commit/13d29cdde641216c0bb7ee8ec3229f865c7dc51a
{
  lib,
  pkgs,
  ...
}:
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }: {
          options.files = lib.mkOption {
            type = lib.types.attrsOf lib.types.path;
            default = { };
          };

          # stable links into the per-user profile: src/maid/modules/file.nix#L116-L140
          config.packages =
            lib.mapAttrs' (path: lib.nameValuePair "home-files/${path}") config.files
            // {
              # L, not L+: never clobber user files
              "etc/xdg/user-tmpfiles.d/home.conf" =
                config.files
                |> lib.mapAttrsToList (
                  path: _:
                  "L '${config.home}/${path}' - - - - /etc/profiles/per-user/${config.name}/home-files/${path}\n"
                )
                |> lib.concatStrings
                |> pkgs.writeText "home.conf";
            }
            |> pkgs.linkFarm "home-files"
            |> lib.optional (config.files != { });
        }
      )
    );
  };

  config.environment.pathsToLink = [ "/home-files" ];

  # drop links of removed files: src/maid/modules/core.nix#L75-L127
  config.system.userActivationScripts.home-files = ''
    new=/etc/profiles/per-user/$USER/etc/xdg/user-tmpfiles.d/home.conf
    old=$HOME/.local/state/home-files.conf
    [ -e "$new" ] || new=/dev/null
    [ -e "$old" ] && grep -vxFf "$new" "$old" | cut -d"'" -f2 | while read -r link; do [ -e "$link" ] || rm -f "$link"; done
    mkdir -p "$HOME/.local/state" && cp "$new" "$old"
  '';
}
