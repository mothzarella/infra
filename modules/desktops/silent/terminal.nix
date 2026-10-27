{
  aspects.silent.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.silent.theme) c ansi monoFont;
    in
    {
      console.colors = ansi;

      programs.foot = {
        enable = true;
        settings = {
          main.font = "${monoFont}:pixelsize=16";
          colors-dark = {
            background = c.bg;
            foreground = c.fg;
            selection-background = c.visual;
            selection-foreground = c.fg;
          }
          // lib.listToAttrs (
            lib.imap0 (
              i: lib.nameValuePair (if i < 8 then "regular${toString i}" else "bright${toString (i - 8)}")
            ) ansi
          );
        };
      };
      environment.sessionVariables.TERMINAL = lib.getExe pkgs.foot;
      xdg.terminal-exec = {
        enable = true;
        settings.default = [ "foot.desktop" ];
      };
    };
}
