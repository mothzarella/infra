# mango session: bar, launcher, lock, idle, notifications
{ config, ... }:
let
  mango = pkgs: pkgs.mango.override { enableXWayland = false; };
in
{
  aspects.silent = {
    includes = [ config.aspects.desktop ];

    nixos =
      { config, pkgs, ... }:
      {
        hardware.graphics.enable = true;
        environment.systemPackages = [
          (mango pkgs)
          pkgs.wl-clipboard-rs # wl-clipboard
          pkgs.libnotify # notify-send
          pkgs.wlr-randr # xrandr
        ];

        programs.chromium.extraOpts.BrowserThemeColor = "#${config.silent.theme.c.bg}";

        services.dbus.packages = [ pkgs.fnott ]; # notifications

        security.pam.services.waylock = { };
      };

    user =
      {
        lib,
        pkgs,
        osConfig,
        ...
      }:
      let
        inherit (osConfig.silent.theme)
          c
          barFont
          cjkFont
          monoFont
          tags
          cursor
          cursorSize
          ;
        exe = lib.getExe;
        waylock = "${exe pkgs.waylock} -fork-on-lock -init-color 0x${c.bg} -input-color 0x${c.keyword} -fail-color 0x${c.error}";
        wlopm = exe pkgs.wlopm;
        grim = exe pkgs.grim;
        brightnessctl = exe pkgs.brightnessctl;
        wpctl = lib.getExe' pkgs.wireplumber "wpctl";
        wmenu = pkgs.wmenu.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace menu.c --replace-fail "line_height = height + 2" "line_height = height + 4"
            # bar palette as default, for every caller
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
        gtk = pkgs.writeText "settings.ini" ''
          [Settings]
          gtk-application-prefer-dark-theme=1
          gtk-cursor-theme-name=${cursor}
          gtk-cursor-theme-size=${toString cursorSize}
        '';
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

            # one window centered, otherwise 0.5+0.5 fill the screen
            tagrule=id:*,layout_name:scroller
            circle_layout=scroller,tile,monocle
            scroller_structs=0
            scroller_default_proportion=0.5
            scroller_proportion_preset=0.5,0.75,1.0

            cursor_theme=${cursor}
            cursor_size=${toString cursorSize}

            # tty login: logind sets "tty"
            env=XDG_SESSION_TYPE,wayland

            exec-once=${exe pkgs.wbg} -s ${wallpaper}
            exec-once=${exe pkgs.wlsunset} -l 41.9 -L 12.5
            exec-once=${exe pkgs.swayidle} -w
            exec-once=${exe pkgs.yambar}

            xkb_rules_model=${osConfig.services.xserver.xkb.model}
            xkb_rules_layout=${osConfig.services.xserver.xkb.layout}
            xkb_rules_variant=${osConfig.services.xserver.xkb.variant}
            xkb_rules_options=${osConfig.services.xserver.xkb.options}

            # no parent, no fixed size
            windowrule=isfloating:1,appid:^xdg-desktop-portal
            windowrule=isfloating:1,title:^Picture in picture$

            bind=SUPER,Return,spawn,${exe pkgs.xdg-terminal-exec}
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
