# Teclast F6: Celeron N3350 (Apollo Lake), Intel HD 500 (8086:5a85), QCA9377 WiFi/BT
{config, ...}: {
  hosts.kiwi.users = [config.aspects.tar];

  aspects.kiwi = {
    includes = with config.aspects; [
      anssi
      bluetooth
      desktop
      disko
      minimal
      mullvad
      networking
      preservation
      secureboot
    ];
    nixos = {
      lib,
      pkgs,
      ...
    }: {
      specialisation.safe.configuration = config.aspects.nomodeset.nixos;

      time.timeZone = "Europe/Rome";
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";

      # --------------------------------------------------------------- hardware
      disko.devices.disk.main = {
        device = "/dev/disk/by-id/ata-Teclast_128GB_NA850-2280_AA000000000112608242";
        content.partitions.root.content = {
          settings.bypassWorkqueues = true; # SSD, lower latency
          content.subvolumes = lib.genAttrs ["/root" "/nix" "/persistent"] (_: {
            mountOptions = lib.mkForce ["compress=zstd:1" "noatime"]; # weak CPU
          });
        };
      };

      hardware.facter.reportPath = ./facter.json;

      hardware.enableRedistributableFirmware = false;
      hardware.cpu.intel.updateMicrocode = true;
      hardware.firmware = [
        (pkgs.runCommand "kiwi-firmware" {} ''
          cd ${pkgs.linux-firmware}/lib/firmware
          mkdir -p $out/lib/firmware
          cp -rL --parents --no-preserve=mode ath10k/QCA9377 qca/*_usb_00000302* i915/bxt_* $out/lib/firmware # wifi, bt, gpu
        '')
      ];

      hardware.graphics.extraPackages = [pkgs.intel-media-driver];
      environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD"; # driver Gen8+

      zramSwap.enable = true; # slow SSD (8GB RAM)
      boot.kernel.sysctl."vm.swappiness" = 180; # zram beats dropping page cache
      boot.kernel.sysctl."vm.page-cluster" = 0; # no swap readahead on zram

      services.thermald.enable = true;

      services.tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "schedutil"; # SAV falls back to BAT
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 1;
          CPU_BOOST_ON_SAV = 0; # 1.1 GHz cap, no 2.4 GHz burst
          USB_EXCLUDE_BTUSB = 1;
        };
      };

      boot.kernelParams = ["btusb.enable_autosuspend=0"]; # QCA BT drops on autosuspend

      system.stateVersion = "26.05";
    };
  };
}
