{
  aspects.networking = {
    nixos = {
      hardware.facter.detected.dhcp.enable = false; # NM does DHCP

      networking.networkmanager = {
        enable = true;
        wifi.backend = "iwd";
        dns = "systemd-resolved";
        # privacy
        connectionConfig."ipv4.dhcp-send-hostname" = false;
        connectionConfig."ipv6.dhcp-send-hostname" = false;
        ethernet.macAddress = "stable";
      };

      # NM ignores wifi.macAddress with iwd
      networking.wireless.iwd.settings.General.AddressRandomization = "network";
      networking.modemmanager.enable = false; # no WWAN modem
      systemd.services.NetworkManager-wait-online.enable = false; # no boot stall

      # DNS cache, no LLMNR
      services.resolved = {
        enable = true;
        settings.Resolve.LLMNR = false;
      };

      # generic pool, the nixos.pool vendor zone reveals the distro
      networking.timeServers = map (n: "${toString n}.pool.ntp.org") [0 1 2 3];

      services.usbmuxd.enable = true; # iPhone USB tethering (ipheth pairing)

      networking.nftables.enable = true;

      # ignore ICMPv6 redirects (IPv4 in ANSSI R12)
      boot.kernel.sysctl = {
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
      };

      preservation.preserveAt."/persistent".directories = [
        {
          directory = "/etc/NetworkManager/system-connections";
          mode = "0700";
        }
        "/var/lib/NetworkManager"
        {
          directory = "/var/lib/iwd"; # known networks, drives autoconnect
          mode = "0700";
        }
        {
          directory = "/var/lib/lockdown"; # iPhone pair records
          user = "usbmux";
          group = "usbmux";
          mode = "0700";
        }
      ];
    };
    user.extraGroups = ["networkmanager"];
  };
}
