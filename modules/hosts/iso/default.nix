{
  config,
  inputs,
  ...
}:
{
  hosts.iso = { };

  aspects.iso.includes = [ config.aspects.nix ];
  aspects.iso.nixos =
    {
      config,
      lib,
      modulesPath,
      pkgs,
      ...
    }:
    let
      name = "${config.networking.hostName}-${config.system.nixos.release}-${
        inputs.self.shortRev or "dirty"
      }-${pkgs.stdenv.hostPlatform.uname.processor}";
    in
    {
      imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

      image.baseName = lib.mkImageMediaOverride name;
      isoImage = {
        volumeID = lib.mkImageMediaOverride name;
        appendToMenuLabel = "";
        edition = "";
        squashfsCompression = "zstd -Xcompression-level 6"; # default 19 builds much slower
      };

      networking.modemmanager.enable = false;

      zramSwap.enable = true; # live system runs from ram

      nix.settings.flake-registry = ""; # flake is embedded

      # "too many open files" on big installs
      security.pam.loginLimits = [
        {
          domain = "*";
          item = "nofile";
          type = "-";
          value = "65536";
        }
      ];
    };

  flake.packages.x86_64-linux.iso = config.flake.nixosConfigurations.iso.config.system.build.isoImage;
}
