# nixinstall <host>: partition, set passwords, create the sops key, install the embedded flake
{ inputs, ... }:
{
  aspects.iso.nixos =
    { config, pkgs, ... }:
    let
      nixinstall = pkgs.writeShellApplication {
        name = "nixinstall";
        runtimeInputs = [
          (pkgs.disko.override { nix = config.nix.package; }) # lix
          config.nix.package
          pkgs.mkpasswd # not busybox: real yescrypt
          pkgs.age
          config.system.build.nixos-install
        ];
        text = ''
          host=''${1:?usage: nixinstall <host>  (FLAKE=<ref> overrides the embedded flake)}
          flake=''${FLAKE:-${inputs.self}}
          export NIX_CONFIG="accept-flake-config = true" # lix asks y/n for flake nixConfig

          disko --mode destroy,format,mount --yes-wipe-all-disks --flake "$flake#$host"

          # hashedPasswordFile must exist before first boot (mutableUsers = false)
          for entry in $(nix eval --raw "$flake#nixosConfigurations.$host.config.users.users" --apply '
            us: builtins.attrValues us
              |> builtins.filter (u: u.hashedPasswordFile != null)
              |> map (u: u.name + ":" + u.hashedPasswordFile)
              |> toString'); do
            while :; do
              IFS= read -rsp "password for ''${entry%%:*}: " pw && echo
              IFS= read -rsp "again: " again && echo
              [[ $pw == "$again" ]] && break
              echo "mismatch"
            done
            install -D -m 600 /dev/null "/mnt''${entry#*:}"
            mkpasswd -m yescrypt -s <<< "$pw" > "/mnt''${entry#*:}"
          done

          # sops age key, the public half goes in .sops.yaml
          keyfile=$(nix eval --raw "$flake#nixosConfigurations.$host.config" --apply 'c: c.sops.age.keyFile or ""')
          if [[ -n $keyfile && ! -e /mnt$keyfile ]]; then
            install -d -m 700 "$(dirname "/mnt$keyfile")"
            age-keygen -o "/mnt$keyfile"
          fi

          mkdir -p /mnt/tmp # not in the live ram
          TMPDIR=/mnt/tmp nixos-install --flake "$flake#$host" --no-root-passwd --no-channel-copy
        '';
      };
    in
    {
      environment.systemPackages = [
        nixinstall
        pkgs.nixos-facter
      ]; # facter.json for new hosts
    };
}
