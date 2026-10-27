{ config, ... }:
{
  aspects.desktop = {
    includes = [
      config.aspects.audio
      config.aspects.bluetooth
      config.aspects.browser
    ];

    nixos = {
      preservation.preserveAt."/persistent".directories = [ "/var/lib/systemd/backlight" ];

      boot.kernelModules = [
        "usb_storage"
        "uas"
        "exfat"
        "ntfs3"
        "isofs"
        "udf"
        "nls_utf8"
      ];
    };
  };
}
