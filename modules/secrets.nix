{ inputs, ... }:
{
  aspects.secrets.nixos =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFile = ../secrets/${config.networking.hostName}.yaml;
        age.keyFile = "/persistent/var/lib/sops-nix/key.txt";
        age.sshKeyPaths = [ ];
        gnupg.sshKeyPaths = [ ];
      };
    };
}
