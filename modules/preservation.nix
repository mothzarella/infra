{ inputs, ... }: {
  aspects.preservation.nixos =
    { lib, config, ... }:
    {
      imports = [ inputs.preservation.nixosModules.preservation ];

      fileSystems."/persistent".neededForBoot = true;
      fileSystems."/persistent".options = [
        "nosuid"
        "nodev"
      ];

      preservation = {
        enable = true;
        preserveAt."/persistent".directories = [
          "/var/lib/systemd/timers"
          "/var/lib/systemd/rfkill" # wifi/bt
          "/var/log"
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
        ];
        preserveAt."/persistent".files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
          {
            file = "/var/lib/systemd/random-seed";
            how = "symlink";
            inInitrd = true;
            configureParent = true;
          }
        ]
        ++ lib.optionals config.services.openssh.enable (
          [
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_ed25519_key.pub"
          ]
          |> map (file: {
            inherit file;
            how = "symlink";
            configureParent = true;
          })
        );
      };

      systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

      users.mutableUsers = false; # ephemeral /etc

      services.journald.settings.Journal.SystemMaxUse = "100M"; # /var/log persists (4G cap)
    };
}
