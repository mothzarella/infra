# stock Adwaita shell, behaviour tweaks via Just Perfection
{
  aspects.gnome = {
    nixos =
      { lib, ... }:
      let
        wallpaper = "file://${./wallpaper.png}";
        cursor = {
          cursor-theme = "Bibata-Modern-Classic";
          cursor-size = lib.gvariant.mkInt32 24;
        };
      in
      {
        programs.dconf.profiles.gdm.databases = [ { settings."org/gnome/desktop/interface" = cursor; } ];
        programs.dconf.profiles.user.databases = [
          {
            settings = {
              "org/gnome/shell/extensions/just-perfection" = {
                dash-icon-size = lib.gvariant.mkInt32 48;
                startup-status = lib.gvariant.mkInt32 0; # desktop, not overview
                support-notifier-type = lib.gvariant.mkInt32 0;
                workspace-popup = false;
                window-demands-attention-focus = true;
              };
              "org/gnome/mutter".experimental-features = [ "autoclose-xwayland" ];
              "org/gnome/desktop/interface" = {
                color-scheme = "prefer-dark";
                gtk-theme = "adw-gtk3-dark"; # libadwaita look for GTK3 apps
                icon-theme = "Papirus-Dark";
              }
              // cursor;
              "org/gnome/desktop/background" = {
                picture-uri = wallpaper;
                picture-uri-dark = wallpaper;
              };
              "org/gnome/desktop/peripherals/touchpad" = {
                tap-to-click = true;
                click-method = "areas";
              };
            };
          }
        ];
      };

    user =
      { pkgs, ... }:
      {
        packages = [
          pkgs.adw-gtk3
          pkgs.gnomeExtensions.appindicator
          pkgs.gnomeExtensions.just-perfection
          pkgs.papirus-icon-theme
        ];
      };
  };
}
