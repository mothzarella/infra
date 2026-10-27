# palette and fonts, read by the other silent files as config.silent.theme
{
  aspects.silent = {
    nixos =
      { lib, ... }:
      {
        options.silent.theme = lib.mkOption {
          type = lib.types.raw;
          readOnly = true;
        };

        config.silent.theme =
          let
            c = {
              bg = "141415";
              inactiveBg = "1c1c24";
              fg = "cdcdcd";
              comment = "606079";
              builtin = "b4d4cf";
              func = "c48282";
              number = "e0a363";
              property = "c3c3d5";
              constant = "aeaed1";
              parameter = "bb9dbd";
              visual = "333738";
              error = "d8647e";
              warning = "f3be7c";
              hint = "7e98e8";
              keyword = "6e94b2";
              type = "9bb4bc";
              plus = "7fa563";
            };
          in
          {
            inherit c;
            # 16 ANSI colors: console, foot
            ansi = [
              c.bg
              c.error
              c.plus
              c.warning
              c.keyword
              c.parameter
              c.type
              c.fg
              c.comment
              c.func
              c.plus
              c.number
              c.hint
              c.constant
              c.builtin
              c.property
            ];
            barFont = "Terminus";
            cjkFont = "Ark Pixel Tags";
            monoFont = "JetBrainsMono Nerd Font Mono";
            tags = [
              "壹"
              "貳"
              "參"
              "肆"
              "伍"
              "陸"
              "柒"
              "捌"
              "玖"
            ];
            cursor = "Bibata-Modern-Classic";
            cursorSize = 24;
          };
      };

    user =
      { pkgs, ... }:
      {
        packages = [ pkgs.bibata-cursors ];
      };
  };
}
