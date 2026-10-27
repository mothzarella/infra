{
  aspects.audio = {
    nixos = {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      security.rtkit.enable = true;

      boot.kernelModules = [
        "snd_usb_audio"
        "snd_seq"
      ];
    };

    user.preserve.directories = [ ".local/state/wireplumber" ];
  };
}
