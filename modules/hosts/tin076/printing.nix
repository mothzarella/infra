{
  aspects.tin076.nixos = {
    services = {
      printing.enable = true;
      printing.browsed.enable = false; # CVE-2024-47176
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
        publish = {
          enable = true;
          addresses = true;
        };
      };
      resolved.settings.Resolve.MulticastDNS = false; # avahi owns mDNS
    };

    preservation.preserveAt."/persistent".directories = [ "/var/lib/cups" ];
  };
}
