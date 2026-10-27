{
  aspects.kiwi.nixos =
    { pkgs, ... }:
    {
      hardware = {
        facter.reportPath = ./facter.json;

        enableRedistributableFirmware = false;
        cpu.intel.updateMicrocode = true;
        firmware = [
          (pkgs.runCommand "kiwi-firmware" { } ''
            cd ${pkgs.linux-firmware}/lib/firmware
            mkdir -p $out/lib/firmware
            cp -rL --parents --no-preserve=mode ath10k/QCA9377 qca/*_usb_00000302* i915/bxt_* $out/lib/firmware # wifi, bt, gpu
          '')
        ];

        graphics.extraPackages = [ pkgs.intel-media-driver ];
      };
      environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD"; # Gen8+

      boot.kernelParams = [ "btusb.enable_autosuspend=0" ]; # QCA BT drops on autosuspend

      services.thermald.enable = true;

      services.tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "schedutil"; # SAV falls back to BAT
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 1;
          CPU_BOOST_ON_SAV = 0; # 1.1 GHz cap
          USB_EXCLUDE_BTUSB = 1;
        };
      };
    };
}
