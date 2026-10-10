{
  # NIS2 anti-malware: on-access blocking, daily full scan, hourly signature updates
  aspects.antivirus.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      homes =
        config.users.users
        |> lib.attrValues
        |> lib.filter (u: u.isNormalUser)
        |> map (u: u.home);
    in
    {
      services.clamav = {
        updater.enable = true;
        fangfrisch.enable = true; # urlhaus + sanesecurity on top of the official db
        scanner.enable = true; # clamdscan, 04:00 (Persistent below catches missed runs)
        clamonacc.enable = true;

        daemon.enable = true;
        daemon.settings = {
          LogSyslog = true; # detections land in the journal (audit evidence)
          LogTime = true;
          ExtendedDetectionInfo = true;

          OnAccessIncludePath = [
            "/home"
            "/tmp"
            "/var/tmp"
          ];
          # rootless docker layers: huge inotify tree, scanned on pull anyway
          OnAccessExcludePath = map (h: "${h}/.local/share/docker") homes;
          OnAccessPrevention = true; # deny open() of infected files
          OnAccessExtraScanning = true; # also scan on create/move
          OnAccessExcludeRootUID = true; # clamdscan, btrbk, activation
          # nix builds unpack sources in /tmp as nixbld*
          OnAccessExcludeUID =
            config.users.users
            |> lib.filterAttrs (n: _: lib.hasPrefix "nixbld" n)
            |> lib.mapAttrsToList (_: u: toString u.uid);
        };
      };

      systemd.timers.clamdscan.timerConfig.Persistent = true; # laptop is off at 04:00
      systemd.services.clamdscan.serviceConfig = {
        Nice = 19;
        IOSchedulingClass = "idle";
      };

      # pop a desktop notification for every detection (wheel reads the system journal)
      systemd.user.services.clamav-notify = {
        description = "ClamAV detection notifications";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        path = [
          config.systemd.package
          pkgs.libnotify
        ];
        script = ''
          journalctl -f -n0 -o cat --grep 'FOUND' \
            -u clamav-daemon.service -u clamav-clamonacc.service -u clamdscan.service |
            while IFS= read -r line; do
              notify-send -u critical -a ClamAV "Malware blocked" "$line"
            done
        '';
        serviceConfig.Restart = "on-failure";
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
