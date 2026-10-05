{
  aspects.xdg.nixos.environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";

    HISTFILE = "$HOME/.local/state/bash/history"; # ~/.bash_history
    GIT_CONFIG_GLOBAL = "$HOME/.config/git/config"; # ~/.gitconfig
    ABDUCO_SOCKET_DIR = "$XDG_RUNTIME_DIR"; # ~/.abduco
  };
}
