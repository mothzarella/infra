# single disk: ESP + LUKS (TPM2) + btrfs; hosts set the device
{ inputs, ... }:
{
  aspects.storage.nixos = {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices.disk.main = {
      type = "disk";
      content = {
        type = "gpt";

        partitions.esp = {
          name = "ESP";
          type = "EF00";
          size = "1G";

          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        partitions.root = {
          size = "100%";

          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            settings.crypttabExtraOpts = [
              "tpm2-device=auto"
              "tpm2-measure-pcr=yes"
            ]; # PCR 15

            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];

              subvolumes =
                {
                  "/root" = "/";
                  "/nix" = "/nix";
                  "/persistent" = "/persistent";
                }
                |> builtins.mapAttrs (
                  _: mountpoint: {
                    inherit mountpoint;
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  }
                );
            };
          };
        };
      };
    };

    services.btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" ];
    };
  };
}
