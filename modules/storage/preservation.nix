# state that survives the rollback lives in /persistent
{ inputs, ... }:
{
  aspects.storage = {
    nixos =
      { config, lib, ... }:
      {
        imports = [ inputs.preservation.nixosModules.preservation ];

        # per-user state, set by the aspects in their user block
        options.users.users = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options.preserve = {
                directories = lib.mkOption {
                  type = lib.types.listOf lib.types.raw;
                  default = [ ];
                };
                files = lib.mkOption {
                  type = lib.types.listOf lib.types.raw;
                  default = [ ];
                };
              };
            }
          );
        };

        config = {
          fileSystems."/persistent".neededForBoot = true;
          fileSystems."/persistent".options = [
            "nosuid"
            "nodev"
          ];

          preservation = {
            enable = true;
            preserveAt."/persistent" = {
              directories = [
                "/var/lib/systemd/timers"
                "/var/lib/systemd/rfkill"
                "/var/log"
                {
                  directory = "/var/lib/nixos";
                  inInitrd = true;
                }
              ];
              files = [
                {
                  file = "/etc/machine-id";
                  inInitrd = true;
                }
                {
                  file = "/var/lib/systemd/credential.secret"; # systemd-creds key (libvirt secrets)
                  mode = "0400";
                }
                {
                  file = "/var/lib/systemd/random-seed";
                  how = "symlink";
                  inInitrd = true;
                  configureParent = true;
                }
              ];
              users =
                config.users.users |> lib.filterAttrs (_: u: u.isNormalUser) |> lib.mapAttrs (_: u: u.preserve);
            };
          };

          systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

          users.mutableUsers = false; # ephemeral /etc
          services = {
            userborn.passwordFilesLocation = "/var/lib/nixos";
            journald.settings.Journal.SystemMaxUse = "100M"; # /var/log persists
          };
        };
      };

    user =
      { name, ... }:
      {
        hashedPasswordFile = "/persistent/passwords/${name}";
      };
  };
}
