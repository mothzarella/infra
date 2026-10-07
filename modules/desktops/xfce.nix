{ config, ... }: {
  aspects.xfce = {
    includes = with config.aspects; [
      audio
      chromium
      xdg
    ];

    nixos =
      { lib, users, ... }:
      {
        services.xserver.desktopManager.xfce = {
          enable = true;
          enableWaylandSession = true;
        };
        programs.nm-applet.enable = true; # xfce has no network GUI (wifi, 802.1X, VPN)

        preservation.preserveAt."/persistent".directories = [ "/var/lib/systemd/backlight" ];
        preservation.preserveAt."/persistent".users = lib.genAttrs users (_: {
          directories = [
            ".config/xfce4"
            ".local/share/keyrings" # xfce turns on gnome-keyring
          ];
        });
      };
  };
}
