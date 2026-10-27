{
  aspects.gnome.nixos =
    { lib, pkgs, ... }:
    {
      programs.dconf.profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 600;
            "org/gnome/desktop/screensaver" = {
              lock-enabled = true;
              lock-delay = lib.gvariant.mkUint32 0;
            };
            "org/gnome/desktop/lockdown".disable-user-switching = true;
            "org/gnome/shell" = {
              disable-user-extensions = false;
              enabled-extensions = [
                pkgs.gnomeExtensions.appindicator.extensionUuid
                pkgs.gnomeExtensions.just-perfection.extensionUuid
              ];
            };
            "org/gnome/desktop/media-handling".autorun-never = true;
            "org/gnome/system/location".enabled = false;
          };
          locks = [
            "/org/gnome/desktop/session/idle-delay"
            "/org/gnome/desktop/screensaver/lock-enabled"
            "/org/gnome/desktop/screensaver/lock-delay"
            "/org/gnome/desktop/lockdown/disable-user-switching"
            "/org/gnome/shell/disable-user-extensions"
            "/org/gnome/shell/enabled-extensions"
            "/org/gnome/desktop/media-handling/autorun-never"
            "/org/gnome/system/location/enabled"
          ];
        }
      ];
    };
}
