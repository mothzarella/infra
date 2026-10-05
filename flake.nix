{
  nixConfig = {
    abort-on-warn = true;
    allow-import-from-derivation = false;
  };

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.pre-commit.follows = "";

    preservation.url = "github:nix-community/preservation";

    securix.url = "github:cloud-gouv/securix";
    securix.flake = false;
  };

  outputs = inputs: let
    inherit (inputs.nixpkgs) lib;
  in
    (lib.evalModules {
      specialArgs = {inherit inputs;};
      modules = [./lib/aspects.nix] ++ (./modules |> lib.filesystem.listFilesRecursive |> builtins.filter (f: lib.hasSuffix ".nix" (toString f)));
    }).config.flake;
}
