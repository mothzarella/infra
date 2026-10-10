{ config, ... }:
let
  c = config.theme;
  neovim =
    pkgs:
    pkgs.neovim.override {
      configure = {
        packages.vague.start = [ pkgs.vimPlugins.vague-nvim ];
        customRC = "colorscheme vague";
      };
    };
in
{
  aspects.tar = {
    includes = with config.aspects; [ xdg ];

    nixos =
      {
        lib,
        pkgs,
        ...
      }:
      {
        networking.stevenblack.enable = true; # blocklist in /etc/hosts

        environment.sessionVariables = {
          EDITOR = lib.getExe (neovim pkgs);
          VISUAL = lib.getExe (neovim pkgs);
          DO_NOT_TRACK = "1";
        };

        preservation.preserveAt."/persistent".users.tar.directories = [
          "Downloads"
          "Pictures"
          ".config/git"
          {
            directory = ".ssh";
            mode = "0700";
          }
          ".config/claude"
          ".config/nnn"
          ".local/share/zathura"
          ".local/share/zoxide"
          ".local/state/bash"
          ".local/state/nvim"
          ".local/state/wireplumber"
          ".cache/tealdeer"
        ];
      };

    user =
      {
        lib,
        pkgs,
        ...
      }:
      {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        hashedPasswordFile = "/persistent/passwd";

        mimeApps =
          lib.genAttrs [ "application/pdf" "application/epub+zip" ] (_: "org.pwmt.zathura-pdf-mupdf.desktop")
          // (
            [
              "png"
              "jpeg"
              "gif"
              "webp"
              "bmp"
              "tiff"
              "svg+xml"
              "avif"
              "heif"
              "jxl"
            ]
            |> map (t: lib.nameValuePair "image/${t}" "imv.desktop")
            |> lib.listToAttrs
          )
          // {
            "text/plain" = "nvim.desktop";
            "inode/directory" = "nnn.desktop";
          };

        packages = with pkgs; [
          # GUI
          (zathura.override { plugins = [ zathuraPkgs.zathura_pdf_mupdf ]; }) # pdf only
          imv # images

          # CLI
          pfetch
          curl
          openssh # ssh, scp
          sops # secrets/*.yaml
          ripgrep # grep
          fd # find
          sd # sed
          ncdu # du
          bottom # top
          jq # json
          nnn # file manager
          zoxide # cd (w fzf)
          pv # pipe
          tealdeer # tldr
          entr # file watcher
          wiremix # pavucontrol
          abduco # session detach

          claude-code

          (neovim pkgs)
          vis
        ];

        files.".config/zathura/zathurarc" = pkgs.writeText "zathurarc" ''
          set font "Unifont 12"
          set selection-clipboard clipboard
          set adjust-open width
          set window-title-basename true
          set statusbar-home-tilde true

          set default-bg "#${c.bg}"
          set default-fg "#${c.fg}"
          set statusbar-bg "#${c.inactiveBg}"
          set statusbar-fg "#${c.fg}"
          set inputbar-bg "#${c.bg}"
          set inputbar-fg "#${c.fg}"
          set notification-error-bg "#${c.bg}"
          set notification-error-fg "#${c.error}"
          set completion-highlight-bg "#${c.keyword}"
          set completion-highlight-fg "#${c.bg}"
          set index-active-bg "#${c.keyword}"
          set index-active-fg "#${c.bg}"

          set recolor true
          set recolor-lightcolor "#${c.bg}"
          set recolor-darkcolor "#${c.fg}"
          set recolor-keephue true
        '';
      };
  };
}
