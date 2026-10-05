{inputs, ...}: {
  aspects.preservation.nixos = {
    imports = [inputs.preservation.nixosModules.preservation];

    fileSystems."/persistent" = {
      neededForBoot = true;
      options = ["nosuid" "nodev"];
    };

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
      ];
    };

    systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];

    users.mutableUsers = false; # ephemeral /etc

    services.journald.settings.Journal.SystemMaxUse = "100M"; # /var/log persists (4G cap)
  };
}
