{
  aspects.tin076.nixos =
    { pkgs, ... }:
    {
      networking.networkmanager.plugins = [
        pkgs.networkmanager-openconnect
        pkgs.networkmanager-openvpn
      ];
    };
}
