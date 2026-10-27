{
  aspects.networking.nixos = {
    hardware.facter.detected.dhcp.enable = false; # NM or iwd do DHCP

    networking = {
      wireless.iwd.settings.General.AddressRandomization = "network";
      modemmanager.enable = false;

      nftables.enable = true;
    };

    services = {
      resolved.enable = true;
      resolved.settings.Resolve.LLMNR = false;

      usbmuxd.enable = true; # iPhone tethering

      # NTS
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

    boot = {
      # IPv4 in ANSSI R12
      kernel.sysctl."net.ipv6.conf.all.accept_redirects" = 0;
      kernel.sysctl."net.ipv6.conf.default.accept_redirects" = 0;

      kernelModules = [
        # tethering, usb ethernet
        "ipheth"
        "cdc_ether"
        "rndis_host"
        "cdc_ncm"
        "r8152"

        # iwd crypto, WPA-Enterprise
        "af_alg"
        "algif_hash"
        "algif_skcipher"
        "algif_aead"
        "md4"
        "des_generic"
        "des3_ede_x86_64"
        "cmac"
        "ccm"
        "pkcs8_key_parser"
      ];
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/iwd";
        mode = "0700";
      }
      {
        directory = "/var/lib/lockdown";
        user = "usbmux";
        group = "usbmux";
        mode = "0700";
      }
    ];
  };
}
