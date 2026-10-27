{
  aspects.bluetooth.nixos = {
    hardware.bluetooth = {
      enable = true;
      settings.General.Experimental = true;
    };

    boot.kernelModules = [
      "hidp"
      "uhid"
    ];

    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/bluetooth";
        mode = "0700";
      }
    ];
  };
}
