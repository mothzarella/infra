{
  aspects.tin076.nixos =
    { lib, pkgs, ... }:
    {
      services.btrbk.instances.persistent = {
        onCalendar = "hourly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "2h";
          snapshot_preserve = "48h 14d";
          subvolume."/persistent".snapshot_dir = "/persistent/.snapshots";
        };
      };

      systemd.tmpfiles.rules = [ "d /persistent/.snapshots 0700 root root -" ];

      # btrbk's doas rules need GNU readlink -e
      environment.systemPackages = [
        (lib.hiPrio (
          pkgs.runCommand "gnu-readlink" { } ''
            mkdir -p $out/bin
            ln -s ${pkgs.coreutils}/bin/readlink $out/bin/readlink
          ''
        ))
      ];
    };
}
