{
  aspects.tar = {
    nixos = {
      networking.stevenblack.enable = true;

      environment.sessionVariables = {
        DO_NOT_TRACK = "1";
        CLAUDE_CONFIG_DIR = "$HOME/.config/claude";
      };
    };

    user =
      {
        pkgs,
        ...
      }:
      {
        isNormalUser = true;
        extraGroups = [ "wheel" ];

        packages = [
          # GUI
          pkgs.gram # zeditor

          # CLI
          pkgs.curl
          pkgs.pfetch # fastfetch
          pkgs.openssh
          pkgs.sops
          pkgs.ripgrep # grep
          pkgs.fd # find
          pkgs.sd # sed
          pkgs.ncdu # du
          pkgs.bottom # top
          pkgs.jq
          pkgs.nnn
          pkgs.zoxide # cd
          pkgs.pv
          pkgs.tealdeer # tldr
          pkgs.entr
          pkgs.wiremix # pavucontrol
          pkgs.abduco

          pkgs.claude-code

          pkgs.neovim
          pkgs.vis
        ];
      };
  };
}
