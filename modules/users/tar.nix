{config, ...}: {
  aspects.tar.includes = with config.aspects; [xdg];

  aspects.tar.user = {pkgs, ...}: {
    isNormalUser = true;
    extraGroups = ["wheel"];
    hashedPasswordFile = "/persistent/passwd";

    packages = with pkgs; [
      # GUI
      (zathura.override {plugins = [zathuraPkgs.zathura_pdf_mupdf];}) # pdf only
      imv # images

      # CLI
      curl
      ripgrep # grep
      fd # find
      sd # sed
      eza # ls
      ncdu # du
      bottom # top
      jq # json
      nnn # file manager
      gitMinimal # cached, no python
      zoxide # cd (w fzf)
      pv # pipe
      tealdeer # tldr
      entr # file watcher
      wiremix # pavucontrol
      abduco # session detach
      mtm # tmux

      neovim
      vis
    ];

    files.".config/zathura/zathurarc" = pkgs.writeText "zathurarc" ''
      set font "Unifont 12"
      set selection-clipboard clipboard
      set adjust-open width
      set window-title-basename true
      set statusbar-home-tilde true

      set default-bg "#000000"
      set default-fg "#ffffff"
      set statusbar-bg "#000000"
      set statusbar-fg "#ffffff"
      set inputbar-bg "#000000"
      set inputbar-fg "#ffffff"
      set notification-error-bg "#000000"
      set notification-error-fg "#ff5555"
      set completion-highlight-bg "#ffffff"
      set completion-highlight-fg "#000000"
      set index-active-bg "#ffffff"
      set index-active-fg "#000000"

      # ctrl+r toggles dark mode
      set recolor-lightcolor "#000000"
      set recolor-darkcolor "#ffffff"
      set recolor-keephue true
    '';
  };

  aspects.tar.nixos.preservation.preserveAt."/persistent".users.tar.directories = [
    "Documents"
    "Downloads"
    "Pictures"
    ".config/git"
    ".config/nnn"
    ".local/share/zathura"
    ".local/share/zoxide"
    ".local/state/bash"
    ".local/state/nvim"
    ".local/state/wireplumber"
    ".cache/tealdeer"
  ];
}
