{
  aspects.tar.nixos =
    { lib, pkgs, ... }:
    {
      environment.sessionVariables = {
        EDITOR = lib.getExe pkgs.neovim;
        VISUAL = lib.getExe pkgs.neovim;
      };
      environment.variables.ABDUCO_SOCKET_DIR = "$XDG_RUNTIME_DIR";

      programs.bash = {
        interactiveShellInit = ''
          set -o vi # v: edit the line in $VISUAL
          # vi mode shown by the cursor: bar insert, block command
          bind 'set show-mode-in-prompt on'
          bind 'set vi-ins-mode-string "\1\e[6 q\2"'
          bind 'set vi-cmd-mode-string "\1\e[2 q\2"'
          PS0='\e[0 q' # commands start with the terminal default cursor
          HISTSIZE=10000
        '';
        # OSC 7: new tabs keep the directory, as programs.bash.vteIntegration
        promptInit = ''
          PS1='\[\e]7;file://\h$PWD\a\]\w \$ '
        '';
      };
    };
}
