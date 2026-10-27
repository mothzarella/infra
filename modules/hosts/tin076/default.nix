# Dell Latitude 3550: i7-1355U (Raptor Lake-U), Iris Xe (8086:a7a1), AX211 WiFi/BT
{ config, ... }:
{
  hosts.tin076.users = [ config.aspects.tar ];

  aspects.tin076 = {
    includes = [
      config.aspects.antivirus
      config.aspects.base
      config.aspects.gnome
      config.aspects.jetbrains
      config.aspects.networkmanager
      config.aspects.remote
      config.aspects.virtualisation
    ];

    nixos = {
      # closed lid on AC keeps remote login alive
      services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

      system.stateVersion = "26.11";
    };
  };
}
