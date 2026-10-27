{ config, ... }:
{
  aspects.gnome = {
    includes = [ config.aspects.desktop ];

    nixos =
      { pkgs, ... }:
      {
        services = {
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
          gnome = {
            core-apps.enable = false;
            gnome-browser-connector.enable = false;
            gnome-initial-setup.enable = false;
            gnome-online-accounts.enable = false;
            gnome-user-share.enable = false;
            localsearch.enable = false;
            rygel.enable = false;
            tinysparql.enable = false;
          };
          dleyna.enable = false;
          geoclue2.enable = false;
          sysprof.enable = true;

          pipewire.wireplumber.extraConfig."90-fallback-sink" = {
            "wireplumber.components" = [
              {
                name = "fallback-sink.lua";
                type = "script/lua";
                provides = "custom.fallback-sink";
              }
            ];
            "wireplumber.profiles".main."custom.fallback-sink" = "required";
          };
        };

        systemd.user.services = {
          "org.gnome.SettingsDaemon.Smartcard".enable = false;
          "org.gnome.SettingsDaemon.UsbProtection".enable = false;
          "org.gnome.SettingsDaemon.Wwan".enable = false;
        };

        i18n.inputMethod.enable = false;

        environment = {
          systemPackages = [
            pkgs.nautilus
            pkgs.gnome-console
            pkgs.gnome-text-editor
            pkgs.loupe
            pkgs.papers
            pkgs.gaphor
            pkgs.bibata-cursors
          ];
          gnome.excludePackages = [
            pkgs.gnome-color-manager
            pkgs.gnome-tour
            pkgs.gnome-user-docs
            pkgs.gst-thumbnailers
            pkgs.orca
            pkgs.xdg-user-dirs
            pkgs.xdg-user-dirs-gtk
          ];
        };

        xdg = {
          mime.defaultApplications = {
            "inode/directory" = "org.gnome.Nautilus.desktop";
            "image/*" = "org.gnome.Loupe.desktop";
            "application/pdf" = "org.gnome.Papers.desktop";
            "application/epub+zip" = "org.gnome.Papers.desktop";
            "x-scheme-handler/terminal" = "org.gnome.Console.desktop";
          };
          terminal-exec = {
            enable = true;
            settings.default = [ "org.gnome.Console.desktop" ];
          };
        };
      };

    user.preserve = {
      directories = [
        ".config/dconf"
        ".config/gtk-3.0"
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
      ];
      files = [ ".config/monitors.xml" ];
    };
  };
}
