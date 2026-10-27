{
  aspects.vpn.nixos = {
    services.mullvad-vpn.enable = true;
    boot.kernelModules = [ "wireguard" ];

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/etc/mullvad-vpn";
        mode = "0700";
      }
    ];
  };
}
