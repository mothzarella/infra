{ inputs, ... }: {
  aspects.disko.nixos = {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices.disk.main = {
      type = "disk";
      content = {
        type = "gpt";

        partitions.esp = {
          name = "ESP"; # partlabel disk-main-ESP, matches the formatted disk
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

    services.btrfs.autoScrub.enable = true;
    services.btrfs.autoScrub.fileSystems = [ "/" ];

    boot.initrd.systemd.services.rollback = {
      wantedBy = [ "initrd.target" ];
      after = [ "systemd-cryptsetup@cryptroot.service" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";

      # rotate /root into old_roots each boot, prune after 30d (no findutils in initrd)
      script = ''
        shopt -s nullglob
        mkdir -p /mnt
        mount -o subvol=/ /dev/mapper/cryptroot /mnt

        if [[ -e /mnt/root ]]; then
          mkdir -p /mnt/old_roots
          mv /mnt/root "/mnt/old_roots/$(date -d "@$(stat -c %Y /mnt/root)" +%F_%T)"
        fi

        cutoff=$(date -d '-30 days' +%s)
        for old in /mnt/old_roots/*; do
          if (($(stat -c %Y "$old") < cutoff)); then
            btrfs subvolume delete -R "$old"
          fi
        done

        btrfs subvolume create /mnt/root
        umount /mnt
      '';
    };
  };
}
