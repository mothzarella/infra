{ config, ... }: {
  aspects = {
    networking.nixos = {
      hardware.facter.detected.dhcp.enable = false; # NM or iwd do DHCP

      networking = {
        wireless.iwd.settings.General.AddressRandomization = "network";
        modemmanager.enable = false; # no WWAN modem

        nftables.enable = true;
      };

      services = {
        resolved.enable = true;
        resolved.settings.Resolve.LLMNR = false;

        usbmuxd.enable = true; # iPhone USB tethering (ipheth pairing)

        # authenticated time (NTS)
        ntpd-rs = {
          enable = true;
          useNetworkingTimeServers = false;
          settings.source =
            map
              (address: {
                mode = "nts";
                inherit address;
              })
              [
                "ptbtime1.ptb.de"
                "ptbtime2.ptb.de"
                "nts.netnod.se"
                "nts.time.nl"
                "time.cloudflare.com"
              ];
        };
      };

      # ignore ICMPv6 redirects (IPv4 in ANSSI R12)
      boot.kernel.sysctl."net.ipv6.conf.all.accept_redirects" = 0;
      boot.kernel.sysctl."net.ipv6.conf.default.accept_redirects" = 0;

      preservation.preserveAt."/persistent".directories = [
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

    # ------------------------------------------------------------ network-manager
    networkmanager = {
      includes = [ config.aspects.networking ];

      nixos = {
        networking.networkmanager = {
          enable = true;
          wifi.backend = "iwd";
          dns = "systemd-resolved";
          # privacy
          connectionConfig."ipv4.dhcp-send-hostname" = false;
          connectionConfig."ipv6.dhcp-send-hostname" = false;
          ethernet.macAddress = "stable";
        };

        systemd.services.NetworkManager-wait-online.enable = false; # no boot stall

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

    # ------------------------------------------------------------------------ iwd
    iwd = {
      includes = [ config.aspects.networking ];

      nixos = {
        networking = {
          useDHCP = false; # no dhcpcd
          wireless.iwd = {
            enable = true;
            settings = {
              General.EnableNetworkConfiguration = true; # built-in DHCP
              Network.NameResolvingService = "systemd"; # resolved
            };
          };
        };

        # takes USB tethering (networkd)
        systemd.network = {
          enable = true;
          wait-online.enable = false; # no boot stall
          networks."40-ipheth" = {
            matchConfig.Driver = "ipheth";
            networkConfig.DHCP = "ipv4";
          };
        };
      };
    };
  };
}
