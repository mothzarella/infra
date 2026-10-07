{
  aspects.networking.nixos = {
    hardware.facter.detected.dhcp.enable = false; # NM does DHCP

    networking = {
      networkmanager = {
        enable = true;
        wifi.backend = "iwd";
        dns = "systemd-resolved";
        # privacy
        connectionConfig."ipv4.dhcp-send-hostname" = false;
        connectionConfig."ipv6.dhcp-send-hostname" = false;
        ethernet.macAddress = "stable";
      };

      # NM ignores wifi.macAddress with iwd
      wireless.iwd.settings.General.AddressRandomization = "network";
      modemmanager.enable = false; # no WWAN modem

      # generic pool, nixos.pool vendor zone reveals the distro
      timeServers = map (n: "${toString n}.pool.ntp.org") [
        0
        1
        2
        3
      ];

      nftables.enable = true;
    };

    systemd.services.NetworkManager-wait-online.enable = false; # no boot stall

    services = {
      resolved.enable = true;
      resolved.settings.Resolve.LLMNR = false;

      usbmuxd.enable = true; # iPhone USB tethering (ipheth pairing)
    };

    # ignore ICMPv6 redirects (IPv4 in ANSSI R12)
    boot.kernel.sysctl."net.ipv6.conf.all.accept_redirects" = 0;
    boot.kernel.sysctl."net.ipv6.conf.default.accept_redirects" = 0;

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

  aspects.networking.user.extraGroups = [ "networkmanager" ];
}
