{ config, ... }: {
  aspects.gnome = {
    includes = with config.aspects; [
      audio
      chromium
      xdg
    ];

    nixos =
      {
        lib,
        pkgs,
        users,
        ...
      }:
      {
        services = {
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;

          gnome = {
            core-apps.enable = false;
            core-developer-tools.enable = false;
            games.enable = false;

            gnome-remote-desktop.enable = true;

            gnome-user-share.enable = false;
            rygel.enable = false;

            gnome-browser-connector.enable = false;
            gnome-initial-setup.enable = false;
            gnome-online-accounts.enable = false;
            localsearch.enable = false;
            tinysparql.enable = false;
          };
          dleyna.enable = false; # DLNA
        };
        systemd.services.gnome-remote-desktop.wantedBy = [ "graphical.target" ];

        networking.firewall.allowedTCPPorts = [
          3389 # remote login
          3390 # desktop sharing
        ];

        environment.systemPackages = with pkgs; [
          nautilus
          gnome-console
          gnome-text-editor
          gnome-calculator
          gnome-system-monitor
          loupe
          papers
          file-roller
          gnome-connections # RDP/VNC client
        ];

        environment.sessionVariables.NIXOS_OZONE_WL = "1";

        # NIS2 PR.AA, STIG V-268086/087
        programs.dconf.profiles.user.databases = [
          {
            settings = {
              "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 300;
              "org/gnome/desktop/screensaver" = {
                lock-enabled = true;
                lock-delay = lib.gvariant.mkUint32 0;
              };
              "org/gnome/desktop/lockdown".disable-user-switching = true;
              "org/gnome/shell".disable-user-extensions = true;
              "org/gnome/desktop/media-handling" = {
                automount-open = false;
                autorun-never = true;
              };
              "org/gnome/desktop/privacy" = {
                remove-old-trash-files = true;
                remove-old-temp-files = true;
                report-technical-problems = false;
              };
              "org/gnome/system/location".enabled = false;
              "org/gnome/desktop/interface".color-scheme = "prefer-dark";
              "org/gnome/desktop/wm/preferences".button-layout = "appmenu:minimize,maximize,close";
              "org/gnome/desktop/peripherals/touchpad".tap-to-click = true;
            };
            locks = [
              "/org/gnome/desktop/session/idle-delay"
              "/org/gnome/desktop/screensaver/lock-enabled"
              "/org/gnome/desktop/screensaver/lock-delay"
              "/org/gnome/desktop/lockdown/disable-user-switching"
              "/org/gnome/shell/disable-user-extensions"
              "/org/gnome/desktop/media-handling/autorun-never"
              "/org/gnome/system/location/enabled"
            ];
          }
        ];

        preservation.preserveAt."/persistent".directories = [
          "/var/lib/systemd/backlight"
          {
            directory = "/var/lib/gnome-remote-desktop"; # remote login TLS cert and credentials
            user = "gnome-remote-desktop";
            group = "gnome-remote-desktop";
            mode = "0700";
          }
        ];
        preservation.preserveAt."/persistent".users = lib.genAttrs users (_: {
          directories = [
            ".config/dconf" # user settings
            ".local/share/keyrings"
            ".local/share/gnome-remote-desktop" # desktop sharing TLS cert
          ];
          files = [ ".config/monitors.xml" ];
        });
      };
  };
}
