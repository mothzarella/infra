{
  aspects.antivirus.nixos =
    { config, ... }:
    {
      services.clamav.updater = {
        enable = true;
        interval = "daily";
      };
      systemd = {
        timers.clamav-freshclam.timerConfig.Persistent = true;
        timers.clamscan.timerConfig.Persistent = true;
        services.clamscan = {
          startAt = "weekly";
          serviceConfig = {
            ExecStart = "${config.services.clamav.package}/bin/clamscan --recursive --infected --max-dir-recursion=40 --move=/var/lib/clamav/quarantine --exclude-dir=^/home/[^/]+/([.]local/share/(docker|containers|Trash)|[.]var/app/[^/]+/cache|(.*/)?([.]cache|[.]git|target|obj|bin/(Debug|Release)|[.]angular|[.]next|[.]nuxt|[.]turbo|[.]parcel-cache))$ /home";
            StateDirectory = "clamav/quarantine";
            StateDirectoryMode = "0700";
            CPUSchedulingPolicy = "idle";
            IOSchedulingClass = "idle";
          };
        };
      };

      preservation.preserveAt."/persistent".directories = [
        {
          directory = "/var/lib/clamav";
          user = "clamav";
          group = "clamav";
        }
      ];
    };
}
