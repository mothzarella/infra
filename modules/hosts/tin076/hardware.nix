{
  aspects.tin076.nixos =
    { pkgs, ... }:
    {
      hardware.facter.reportPath = ./facter.json;
      hardware.graphics.extraPackages = [ pkgs.intel-media-driver ]; # VA-API

      services = {
        power-profiles-daemon.enable = true;
        thermald.enable = true; # DPTF adaptive tables
        fwupd.enable = true;
        hardware.bolt.enable = true;
      };

      boot.kernel.sysctl = {
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;
      };

      preservation.preserveAt."/persistent".directories = [
        {
          directory = "/var/lib/fprint"; # fprintd from facter
          mode = "0700";
        }
        "/var/lib/fwupd"
        "/var/lib/power-profiles-daemon"
        "/var/lib/boltd"
      ];
    };
}
