{ config, ... }:
{
  aspects.iwd = {
    includes = [ config.aspects.networking ];

    nixos = {
      networking = {
        useDHCP = false;
        wireless.iwd = {
          enable = true;
          settings = {
            General.EnableNetworkConfiguration = true;
            Network.NameResolvingService = "systemd";
          };
        };
      };

      # USB tethering
      systemd.network = {
        enable = true;
        wait-online.enable = false;
        networks."40-ipheth" = {
          matchConfig.Driver = "ipheth";
          networkConfig.DHCP = "ipv4";
        };
      };
    };
  };
}
