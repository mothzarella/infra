{
  config,
  inputs,
  lib,
  ...
}:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

  baseline = c: {
    "firewall" = c.networking.firewall.enable;
    "secure boot" = c.boot.lanzaboote.enable;
    "immutable users" = !c.users.mutableUsers;
    "no ssh passwords" =
      !c.services.openssh.enable || !c.services.openssh.settings.PasswordAuthentication;

    # securix preboot
    "R1" = c.security.anssi.rules.R1.enable;
    "R2" = c.security.anssi.rules.R2.enable;
    "R3" = c.security.anssi.rules.R3.enable;
    "R4" = c.security.anssi.rules.R4.enable;
    "R5" = c.security.anssi.rules.R5.enable;
    "R6" = c.security.anssi.rules.R6.enable;
    "R7" = c.security.anssi.rules.R7.enable;
  };

  check =
    name: host:
    let
      fails = lib.attrNames (lib.filterAttrs (_: ok: !ok) (baseline host.config));
    in
    lib.throwIf (fails != [ ]) "baseline ${name}: ${lib.concatStringsSep ", " fails}" (
      pkgs.runCommand "baseline-${name}" { } "touch $out"
    );
in
{
  flake.checks.x86_64-linux = {
    "baseline:kiwi" = check "kiwi" config.flake.nixosConfigurations.kiwi;
    "baseline:tin076" = check "tin076" config.flake.nixosConfigurations.tin076;
  };
}
