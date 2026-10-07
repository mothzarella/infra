{
  aspects.vpn.nixos = {
    services.mullvad-vpn.enable = true;

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/etc/mullvad-vpn";
        mode = "0700";
      }
    ];
  };
}
