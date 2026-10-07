{
  config,
  inputs,
  ...
}:
{
  hosts.iso = { };

  aspects.iso.includes = [ config.aspects.lix ];
  aspects.iso.nixos =
    {
      config,
      lib,
      modulesPath,
      pkgs,
      ...
    }:
    let
      nixinstall = pkgs.writeShellApplication {
        name = "nixinstall";
        runtimeInputs = [
          (pkgs.disko.override { nix = config.nix.package; }) # lix
          config.nix.package
          pkgs.mkpasswd # not busybox: real yescrypt
          config.system.build.nixos-install
        ];
        text = ''
          host=''${1:?usage: nixinstall <host>  (FLAKE=<ref> overrides the embedded flake)}
          flake=''${FLAKE:-${inputs.self}}
          export NIX_CONFIG="accept-flake-config = true" # lix asks y/n for flake nixConfig

          disko --mode destroy,format,mount --yes-wipe-all-disks --flake "$flake#$host"

          # hashedPasswordFile must exist before first boot (mutableUsers = false)
          for entry in $(nix eval --raw "$flake#nixosConfigurations.$host.config.users.users" --apply '
            us: toString (map (u: u.name + ":" + u.hashedPasswordFile)
              (builtins.filter (u: u.hashedPasswordFile != null) (builtins.attrValues us)))'); do
            while :; do
              IFS= read -rsp "password for ''${entry%%:*}: " pw && echo
              IFS= read -rsp "again: " again && echo
              [[ $pw == "$again" ]] && break
              echo "mismatch"
            done
            install -D -m 600 /dev/null "/mnt''${entry#*:}"
            mkpasswd -m yescrypt -s <<< "$pw" > "/mnt''${entry#*:}"
          done

          mkdir -p /mnt/tmp # build on disk and not in the live system's ram
          TMPDIR=/mnt/tmp nixos-install --flake "$flake#$host" --no-root-passwd --no-channel-copy
        '';
      };

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

      environment.systemPackages = [
        nixinstall
        pkgs.nixos-facter
      ]; # facter.json for new hosts

      networking.modemmanager.enable = false; # no WWAN modem

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

      # ---------------------------------- optimizations: no perl, python, extra tools
      nixpkgs.overlays = lib.mkForce [ ]; # re-instantiates the external pkgs
      boot = {
        supportedFilesystems = {
          zfs = false;
          cifs = lib.mkForce false;
          xfs = lib.mkForce false;
        };
        swraid.enable = lib.mkForce false;
      };
      programs.git.package = pkgs.gitMinimal;
      documentation.enable = lib.mkForce false;
      environment.defaultPackages = lib.mkForce [ ];
      services.userborn.enable = true;
      system = {
        switch.enable = false; # immutable
        etc.overlay.enable = true;
        installer.channel.enable = false; # no nixpkgs copy
        extraDependencies = lib.mkForce [ ]; # no offline install
        disableInstallerTools = true;
        tools.nixos-install.enable = true;
        tools.nixos-enter.enable = true;
      };
    };

  flake.packages.x86_64-linux.iso = config.flake.nixosConfigurations.iso.config.system.build.isoImage;
}
