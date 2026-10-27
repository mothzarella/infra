{ inputs, ... }:
{
  aspects.nix.nixos =
    { config, pkgs, ... }:
    {
      imports = [ "${inputs.fix}/nix/modules/nixos.nix" ];

      nix = {
        package = pkgs.lix;
        channel.enable = false;
        registry.nixpkgs.flake = inputs.nixpkgs; # locked (narHash, rev)

        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            "pipe-operator"
          ];
          nix-path = [ "nixpkgs=${inputs.nixpkgs}" ]; # nix-shell -p, <nixpkgs>
          allowed-users = [ "@wheel" ];

          min-free = 5 * 1024 * 1024 * 1024;
          max-free = 15 * 1024 * 1024 * 1024;
          connect-timeout = 5;
          fallback = true;
          warn-dirty = false;
          allow-import-from-derivation = false;

          substituters = [ "https://nix-community.cachix.org" ];
          trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
        };

        optimise.automatic = true;
      };

      systemd.services.system-gc = {
        startAt = "weekly";
        serviceConfig.Type = "oneshot";
        script = ''
          profile=/nix/var/nix/profiles/system
          booted=$(readlink -f /run/booted-system)
          cutoff=$(( $(date +%s) - 14 * 86400 ))
          mapfile -t old < <(ls -1v $profile-*-link | head -n -3)
          del=()
          for g in "''${old[@]}"; do
            [[ $(readlink -f "$g") == "$booted" ]] && continue
            (( $(stat -c %Y "$g") >= cutoff )) && continue
            n=''${g#$profile-}
            del+=("''${n%-link}")
          done
          if (( ''${#del[@]} )); then
            ${config.nix.package}/bin/nix-env -p $profile --delete-generations "''${del[@]}"
            $profile/bin/switch-to-configuration boot # no stale boot entries
          fi
          ${config.nix.package}/bin/nix-store --gc
        '';
      };
      systemd.timers.system-gc.timerConfig.Persistent = true;

      nixpkgs.flake.setNixPath = false; # nix-path in nix.conf (NIX_PATH needs a relogin)

      programs.fix.enable = true;
      environment.shellAliases.fix = "NIX_CONFIG='extra-experimental-features = pipe-operators' fix";

      environment.systemPackages = [ pkgs.gitMinimal ]; # flakes
    };
}
