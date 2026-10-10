{ config, ... }:
let
  mango = pkgs: pkgs.mango.override { enableXWayland = false; };
  barFont = "Terminus";
  cjkFont = "Ark Pixel Tags";
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
  monoFont = "JetBrainsMono Nerd Font Mono";
  c = config.theme;
in
{
  aspects.mango = {
    includes = with config.aspects; [
      audio
      chromium
      theme
      xdg
    ];
    nixos =
      {
        lib,
        pkgs,
        ...
      }:
      {
        hardware.graphics.enable = true;
        environment.systemPackages = with pkgs; [
          (mango pkgs)
          wl-clipboard-rs # wl-clipboard
          libnotify # notify-send
          wlr-randr # xrandr
        ];

        environment.sessionVariables.TERMINAL = lib.getExe pkgs.foot;

        services.dbus.packages = [ pkgs.fnott ]; # notifications

        preservation.preserveAt."/persistent".directories = [ "/var/lib/systemd/backlight" ];

        security.pam.services.waylock = { };
        fonts.packages = [
          pkgs.unifont
          (pkgs.runCommand "terminus-16b" { } ''
            install -Dm444 ${pkgs.terminus_font}/share/fonts/terminus/ter-u16b.otb -t $out/share/fonts/misc
          '')
          (pkgs.runCommand "ark-pixel-tags"
            {
              nativeBuildInputs = [
                pkgs.python3
                pkgs.fonttosfnt
              ];
            }
            ''
              python3 - ${pkgs.ark-pixel-font}/share/fonts/bdf/ark-pixel-12px-monospaced-zh_tw.bdf ${lib.concatStrings tags} > tags.bdf <<'EOF'
              import sys
              src, chars = sys.argv[1], sys.argv[2]
              lines = open(src, encoding="latin1").read().split("\n")
              out = ["STARTFONT 2.1", "FONT -ArkPixel-${cjkFont}-Bold-R-Normal--16-160-75-75-C-130-ISO10646-1",
                     "SIZE 16 75 75", "FONTBOUNDINGBOX 13 16 0 -4", "STARTPROPERTIES 8",
                     'FAMILY_NAME "${cjkFont}"', 'WEIGHT_NAME "Bold"', "PIXEL_SIZE 16",
                     'CHARSET_REGISTRY "ISO10646"', 'CHARSET_ENCODING "1"',
                     "FONT_ASCENT 12", "FONT_DESCENT 4", 'SPACING "C"', "ENDPROPERTIES", f"CHARS {len(chars)}"]
              for c in chars:
                  i = lines.index(f"ENCODING {ord(c)}")
                  j = lines.index("BITMAP", i) + 1
                  k = lines.index("ENDCHAR", j)
                  bm = ["%04X" % ((n | n >> 1) & 0xFFF0) for n in (int(r, 16) for r in lines[j:k])]
                  out += [f"STARTCHAR U+{ord(c):04X}", f"ENCODING {ord(c)}", "SWIDTH 812 0", "DWIDTH 13 0",
                          f"BBX 12 {len(bm)} 0 -1", "BITMAP", *bm, "ENDCHAR"]
              print("\n".join(out + ["ENDFONT"]))
              EOF
              mkdir -p $out/share/fonts/misc
              fonttosfnt -b -c -g 2 -m 2 -o $out/share/fonts/misc/ark-pixel-tags.otb tags.bdf
            ''
          )
          (pkgs.runCommand "jetbrains-mono-nerd-mono" { } ''
            install -Dm444 ${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFontMono-{Regular,Bold}.ttf -t $out/share/fonts/truetype
          '')
        ];
      };

    user =
      {
        lib,
        pkgs,
        osConfig,
        ...
      }:
      let
        exe = lib.getExe;
        waylock = "${exe pkgs.waylock} -fork-on-lock -init-color 0x${c.bg} -input-color 0x${c.keyword} -fail-color 0x${c.error}";
        wlopm = exe pkgs.wlopm;
        grim = exe pkgs.grim;
        brightnessctl = exe pkgs.brightnessctl;
        wpctl = lib.getExe' pkgs.wireplumber "wpctl";
        wmenu = pkgs.wmenu.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace menu.c --replace-fail "line_height = height + 2" "line_height = height + 4"
            # palette defaults like the bar, so every caller (wmenu-run, fnott) matches
            substituteInPlace menu.c \
              --replace-fail '"monospace 10"' '"${barFont}, ${cjkFont}, Bold 16px"' \
              --replace-fail "normalbg = 0x222222ff" "normalbg = 0x${c.bg}ff" \
              --replace-fail "normalfg = 0xbbbbbbff" "normalfg = 0x${c.fg}ff" \
              --replace-fail "promptbg = 0x005577ff" "promptbg = 0x${c.keyword}ff" \
              --replace-fail "promptfg = 0xeeeeeeff" "promptfg = 0x${c.bg}ff" \
              --replace-fail "selectionbg = 0x005577ff" "selectionbg = 0x${c.keyword}ff" \
              --replace-fail "selectionfg = 0xeeeeeeff" "selectionfg = 0x${c.bg}ff"
          '';
        });
        gtk = pkgs.writeText "settings.ini" "[Settings]\ngtk-application-prefer-dark-theme=1\n";
        # 1-bit image: black -> bg, white -> fg
        wallpaper = pkgs.runCommand "wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
          magick ${./wallpaper.png} +level-colors '#${c.bg},#${c.fg}' $out
        '';

        mangoTags = pkgs.writeShellScript "mango-tags" ''
          ${lib.getExe' (mango pkgs) "mmsg"} watch all-tags | ${exe pkgs.jq} --unbuffered -r '
            .all_tags[0].tags
            | map("a\(.index)|bool|\(.is_active)\nu\(.index)|bool|\(.is_urgent)\no\(.index)|bool|\(.client_count > 0)")
            | "\(join("\n"))\n"'
        '';

        cpuGraph = pkgs.writeShellScript "cpu-graph" ''
          bars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
          hist=(0 0 0 0 0 0 0 0 0 0)
          read -r _ u n s i w q sq st _ < /proc/stat
          prev_idle=$((i + w)) prev_total=$((u + n + s + i + w + q + sq + st))
          while sleep 1; do
            read -r _ u n s i w q sq st _ < /proc/stat
            idle=$((i + w)) total=$((u + n + s + i + w + q + sq + st))
            dt=$((total - prev_total)) di=$((idle - prev_idle))
            prev_idle=$idle prev_total=$total
            hist=("''${hist[@]:1}" $((((dt - di) * 7 + dt / 2) / dt)))
            graph=""
            for l in "''${hist[@]}"; do graph+=''${bars[l]}; done
            printf 'cpu|string|%s\n\n' "$graph"
          done
        '';

        tagBinds =
          lib.range 1 9
          |> map toString
          |> lib.concatMapStrings (n: ''
            bind=SUPER,${n},view,${n},0
            bind=SUPER+CTRL,${n},tag,${n},0
          '');
      in
      {
        mimeApps."x-scheme-handler/terminal" = "foot.desktop";

        files = {
          ".config/mango/config.conf" = pkgs.writeText "config.conf" ''
            animation_type_open=zoom
            animation_type_close=zoom
            zoom_initial_ratio=0.95
            zoom_end_ratio=0.95
            fadein_begin_opacity=0
            fadeout_begin_opacity=1
            animation_duration_move=150
            animation_duration_open=120
            animation_duration_close=100
            animation_duration_tag=150
            animation_curve_open=0.22,1,0.36,1
            animation_curve_move=0.22,1,0.36,1
            animation_curve_tag=0.22,1,0.36,1
            animation_curve_close=0.22,1,0.36,1

            # border only on the focused window
            borderpx=2
            no_border_when_single=1
            rootcolor=0x${c.bg}ff
            bordercolor=0x00000000
            focuscolor=0x${c.keyword}ff
            urgentcolor=0x${c.error}ff
            gappih=0
            gappiv=0
            gappoh=0
            gappov=0

            # a single window is centered, otherwise the focused one sticks to an edge so 0.5+0.5 fill the screen
            tagrule=id:*,layout_name:scroller
            circle_layout=scroller,tile,monocle
            scroller_structs=0
            scroller_default_proportion=0.5
            scroller_proportion_preset=0.5,0.75,1.0

            exec-once=${exe pkgs.wbg} -s ${wallpaper}
            exec-once=${exe pkgs.wlsunset} -l 41.9 -L 12.5
            exec-once=${exe pkgs.swayidle} -w
            exec-once=${exe pkgs.yambar}

            xkb_rules_model=${osConfig.services.xserver.xkb.model}
            xkb_rules_layout=${osConfig.services.xserver.xkb.layout}
            xkb_rules_variant=${osConfig.services.xserver.xkb.variant}
            xkb_rules_options=${osConfig.services.xserver.xkb.options}

            # dialogs with a parent or fixed size already float, these have neither
            windowrule=isfloating:1,appid:^xdg-desktop-portal
            windowrule=isfloating:1,title:^Picture in picture$

            bind=SUPER,Return,spawn,${exe pkgs.foot}
            bind=SUPER,d,spawn_shell,${lib.getExe' wmenu "wmenu-run"}
            bind=SUPER+SHIFT,l,spawn,${waylock}
            bind=NONE,Print,spawn,${grim}
            bind=SHIFT,Print,spawn_shell,${grim} -g "$(${exe pkgs.slurp})"
            bind=NONE,XF86MonBrightnessUp,spawn,${brightnessctl} s +5%
            bind=NONE,XF86MonBrightnessDown,spawn,${brightnessctl} s 5%-
            bind=NONE,XF86AudioRaiseVolume,spawn,${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
            bind=NONE,XF86AudioLowerVolume,spawn,${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-
            bind=NONE,XF86AudioMute,spawn,${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle
            bind=SUPER,q,killclient,
            bind=SUPER+SHIFT,e,quit,
            bind=SUPER,r,reload_config,
            bind=SUPER,f,togglefullscreen,
            bind=SUPER,space,togglefloating,
            bind=SUPER,n,switch_layout,
            bind=SUPER,w,switch_proportion_preset,

            bind=SUPER,h,focusdir,left
            bind=SUPER,j,focusdir,down
            bind=SUPER,k,focusdir,up
            bind=SUPER,l,focusdir,right
            bind=SUPER+CTRL,h,exchange_client,left
            bind=SUPER+CTRL,j,exchange_client,down
            bind=SUPER+CTRL,k,exchange_client,up
            bind=SUPER+CTRL,l,exchange_client,right
            ${tagBinds}
            mousebind=SUPER,btn_left,moveresize,curmove
            mousebind=SUPER,btn_right,moveresize,curresize
          '';
          ".config/foot/foot.ini" = (pkgs.formats.ini { }).generate "foot.ini" {
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
              ) osConfig.console.colors
            );
          };

          ".config/gtk-3.0/settings.ini" = gtk;
          ".config/gtk-4.0/settings.ini" = gtk;

          ".config/yambar/config.yml" = (pkgs.formats.yaml { }).generate "config.yml" {
            bar = {
              location = "top";
              height = 20;
              spacing = 8;
              margin = 6;
              font = "${barFont}:style=Bold:pixelsize=16, ${cjkFont}:pixelsize=16";
              background = "00000000";
              foreground = "${c.fg}ff";
              left = [
                {
                  script = {
                    path = "${mangoTags}";
                    content.list.items = lib.imap1 (
                      i: n:
                      let
                        i' = toString i;
                      in
                      {
                        map.conditions = {
                          "a${i'}".string = {
                            text = " ${n} ";
                            foreground = "${c.bg}ff";
                            deco.background.color = "${c.keyword}ff";
                          };
                          "~a${i'} && u${i'}".string.text = "!${n}!";
                          "~a${i'} && ~u${i'}${lib.optionalString (i > 3) " && o${i'}"}".string.text = " ${n} ";
                        };
                      }
                    ) tags;
                  };
                }
              ];
              right = [
                {
                  script = {
                    path = "${cpuGraph}";
                    content.string.text = "{cpu}";
                  };
                }
                {
                  battery = {
                    name = "BAT0";
                    poll-interval = 5000;
                    content.map = {
                      default.string.text = "+{capacity}%";
                      conditions."state == discharging".string.text = "{capacity}%";
                    };
                  };
                }
                {
                  clock = {
                    date-format = "%a %d %b";
                    content.string.text = "{date} {time}";
                  };
                }
              ];
            };
          };

          ".config/fnott/fnott.ini" =
            {
              globalSection = {
                max-width = 400;
                selection-helper = lib.getExe wmenu;
                background = "${c.bg}ff";
                title-color = "${c.fg}ff";
                summary-color = "${c.fg}ff";
                body-color = "${c.fg}ff";
                border-color = "${c.keyword}ff";
                title-font = "${monoFont}:pixelsize=16";
                summary-font = "${monoFont}:pixelsize=16";
                body-font = "${monoFont}:pixelsize=16";
                default-timeout = 5;
              };
              sections.critical = {
                border-color = "${c.error}ff";
                default-timeout = 0;
              };
            }
            |> lib.generators.toINIWithGlobalSection { }
            |> pkgs.writeText "fnott.ini";

          ".config/swayidle/config" = pkgs.writeText "swayidle" ''
            timeout 300 '${waylock}'
            timeout 360 '${wlopm} --off \*' resume '${wlopm} --on \*'
            before-sleep '${waylock}'
            after-resume '${wlopm} --on \*'
          '';
        };
      };
  };
}
