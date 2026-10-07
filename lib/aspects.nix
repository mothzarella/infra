{
  lib,
  config,
  inputs,
  ...
}:
let
  aspect = lib.types.submodule (
    { name, ... }: {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          readOnly = true;
        };
        includes = lib.mkOption {
          type = lib.types.listOf lib.types.raw;
          default = [ ];
        };
        nixos = lib.mkOption {
          type = lib.types.deferredModule;
          default = { };
        };
        user = lib.mkOption {
          type = lib.types.deferredModule;
          default = { };
        };
      };
    }
  );

  # deduplicate aspects
  closure =
    roots:
    let
      node = a: {
        key = a.name;
        aspect = a;
      };
    in
    builtins.genericClosure {
      startSet = map node roots;
      operator = x: map node x.aspect.includes;
    }
    |> map (x: x.aspect);

  host =
    name:
    {
      system,
      users,
    }:
    let
      self = config.aspects.${name};
      nixos = [ self ] ++ users |> closure |> map (a: a.nixos);
      user =
        users
        |> map (
          u: { pkgs, ... }: {
            users.users.${u.name} = _: {
              imports =
                [
                  self
                  u
                ]
                |> closure
                |> map (a: a.user);
              _module.args.pkgs = pkgs;
            };
          }
        );
    in
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        ./home.nix
        {
          networking.hostName = name;
          nixpkgs.hostPlatform = system;
          nixpkgs.config.allowUnfree = true;
        }
      ]
      ++ nixos
      ++ user;
    };
in
{
  options = {
    flake = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.lazyAttrsOf lib.types.raw;
        options.checks = lib.mkOption {
          type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.package);
          default = { };
        };
      };
      default = { };
    };
    aspects = lib.mkOption {
      type = lib.types.lazyAttrsOf aspect;
      default = { };
    };
    hosts = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule {
          options = {
            system = lib.mkOption {
              type = lib.types.str;
              default = "x86_64-linux";
            };
            users = lib.mkOption {
              type = lib.types.listOf lib.types.raw;
              default = [ ];
            };
          };
        }
      );
      default = { };
    };
  };

  config.flake.nixosConfigurations = config.hosts |> lib.mapAttrs host;
  config.flake.checks =
    config.hosts
    |> lib.mapAttrsToList (
      n: h: {
        ${h.system}."configurations:nixos:${n}" =
          config.flake.nixosConfigurations.${n}.config.system.build.toplevel;
      }
    )
    |> lib.mkMerge;
}
