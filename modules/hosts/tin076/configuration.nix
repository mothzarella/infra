# Dell Latitude 3550: i7-1355U (Raptor Lake-U), Iris Xe (8086:a7a1), AX211 WiFi/BT
{ config, ... }: {
  hosts.tin076.users = [ config.aspects.tar ];

  aspects.tin076 = {
    includes = with config.aspects; [
      anssi
      antivirus
      bluetooth
      disko
      gnome
      minimal
      networkmanager
      preservation
      remote
      secrets
      secureboot
      stig
      virtualisation
    ];

    user =
      { pkgs, ... }:
      {
        packages = with pkgs; [
          teams-for-linux

          jetbrains.pycharm

          nodejs

          # java/kotlin
          jetbrains.idea
          jetbrains.rider
          dotnet-sdk_8
          kotlin
          maven
          gradle
        ];
      };

    nixos =
      {
        pkgs,
        ...
      }:
      {
        time.timeZone = "Europe/Rome";
        i18n.defaultLocale = "en_US.UTF-8";

        programs.nix-ld.enable = true;

        services = {
          # hourly undo for /persistent, home included
          # also holds VM disks and ~/.local/share/docker: make them subvolumes if snapshots eat space
          btrbk.instances.persistent = {
            onCalendar = "hourly";
            settings = {
              timestamp_format = "long"; # hourly retention needs the time
              snapshot_preserve_min = "2h";
              snapshot_preserve = "48h 14d";
              subvolume."/persistent".snapshot_dir = "/persistent/.snapshots";
            };
          };

          # office
          printing.enable = true;
          avahi = {
            enable = true; # driverless (IPP Everywhere) printer discovery
            nssmdns4 = true;
            openFirewall = true;
          };
          resolved.settings.Resolve.MulticastDNS = false; # avahi owns mDNS

          # hardware
          power-profiles-daemon.enable = true;
          thermald.enable = true; # DPTF adaptive tables
          fwupd.enable = true;
          hardware.bolt.enable = true; # Thunderbolt device authorization
        };

        systemd.tmpfiles.rules = [ "d /persistent/.snapshots 0700 root root -" ];

        networking.networkmanager = {
          plugins = with pkgs; [
            networkmanager-openconnect # AnyConnect, GlobalProtect, Pulse, Fortinet
            networkmanager-openvpn
          ];
        };

        # --------------------------------------------------------------- hardware
        disko.devices.disk.main = {
          device = "/dev/disk/by-id/nvme-KINGSTON_SNV2S1000G_50026B728358322A";
          content.partitions.root.content.settings.bypassWorkqueues = true; # NVMe
          content.partitions.swap = {
            size = "4G";
            content = {
              type = "swap";
              randomEncryption = true; # fresh key every boot
              discardPolicy = "both";
            };
          };
        };

        hardware.facter.reportPath = ./facter.json;
        hardware.graphics.extraPackages = [ pkgs.intel-media-driver ]; # VA-API (iHD)

        nix.daemonCPUSchedPolicy = "idle";
        nix.daemonIOSchedClass = "idle";

        preservation.preserveAt."/persistent".directories = [
          "/home" # only root is wiped
          "/var/lib/cups"
          {
            directory = "/var/lib/fprint"; # facter
            mode = "0700";
          }
          "/var/lib/fwupd"
          "/var/lib/power-profiles-daemon"
          "/var/lib/boltd"
        ];

        zramSwap.enable = true;
        boot.kernel.sysctl = {
          "vm.swappiness" = 180; # zram > dropping page cache
          "vm.watermark_boost_factor" = 0;
          "vm.watermark_scale_factor" = 125;
          "vm.page-cluster" = 0; # no swap readahead on zram
        };

        system.stateVersion = "26.11";
      };
  };
}
