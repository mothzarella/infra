# RDP: remote login (3389) and sharing of the running session (3390)
{
  aspects.gnome = {
    nixos = {
      systemd = {
        services = {
          gnome-remote-desktop.wantedBy = [ "graphical.target" ];
          gnome-remote-desktop-configuration = {
            path = [ "/run/wrappers" ];
            serviceConfig.UnsetEnvironment = "SHELL";
          };
        };
        user.services.gnome-remote-desktop = {
          wantedBy = [ "gnome-session.target" ];
          unitConfig.ConditionGroup = "users";
          environment.LIBVA_DRIVER_NAME = "none";
        };
      };

      networking.firewall.allowedTCPPorts = [
        3389 # remote login
        3390 # desktop sharing
      ];

      preservation.preserveAt."/persistent".directories = [
        {
          directory = "/var/lib/gnome-remote-desktop";
          user = "gnome-remote-desktop";
          group = "gnome-remote-desktop";
          mode = "0700";
        }
      ];
    };

    user.preserve.directories = [ ".local/share/gnome-remote-desktop" ];
  };
}
