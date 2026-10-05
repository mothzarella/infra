{
  aspects.bluetooth.nixos = {
    hardware.bluetooth.enable = true;

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/bluetooth";
        mode = "0700";
      }
    ];
  };
}
