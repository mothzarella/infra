# Teclast F6: Celeron N3350 (Apollo Lake), Intel HD 500 (8086:5a85), QCA9377 WiFi/BT
{ config, ... }:
{
  hosts.kiwi.users = [ config.aspects.tar ];

  aspects.kiwi = {
    includes = [
      config.aspects.base
      config.aspects.iwd
      config.aspects.silent
      config.aspects.virtualisation
      config.aspects.vpn
    ];

    nixos = {
      specialisation.safe.configuration.boot.kernelParams = [ "nomodeset" ];

      system.stateVersion = "26.05";
    };
  };
}
