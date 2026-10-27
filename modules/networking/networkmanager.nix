{ config, ... }:
{
  aspects.networkmanager = {
    includes = [ config.aspects.networking ];

    nixos = {
      networking.networkmanager = {
        enable = true;
        wifi.backend = "iwd";
        dns = "systemd-resolved";
        ethernet.macAddress = "stable"; # privacy
        connectionConfig = {
          "ipv4.dhcp-send-hostname" = false;
          "ipv6.dhcp-send-hostname" = false;
          # MPTCP loosens rp_filter to 2: https://github.com/cloud-gouv/securix/pull/298
          "connection.mptcp-flags" = "0x1";
        };
      };

      systemd.services.NetworkManager-wait-online.enable = false;

      preservation.preserveAt."/persistent".directories = [
        {
          directory = "/etc/NetworkManager/system-connections";
          mode = "0700";
        }
        "/var/lib/NetworkManager"
      ];
    };

    user.extraGroups = [ "networkmanager" ];
  };
}
