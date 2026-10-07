{ config, ... }:
let
  mango = pkgs: pkgs.mango.override { enableXWayland = false; };
in
{
  aspects.desktop = {
    includes = with config.aspects; [
      audio
      chromium
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
        # only what is run by hand, the rest is referenced by store path
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
        fonts.packages = [ pkgs.unifont ];
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
        waylock = "${exe pkgs.waylock} -fork-on-lock";
        wlopm = exe pkgs.wlopm;
        grim = exe pkgs.grim;
        brightnessctl = exe pkgs.brightnessctl;
        wpctl = lib.getExe' pkgs.wireplumber "wpctl";
        gtk = pkgs.writeText "settings.ini" "[Settings]\ngtk-application-prefer-dark-theme=1\n";

        mangoTags = pkgs.writeShellScript "mango-tags" ''
          ${lib.getExe' (mango pkgs) "mmsg"} watch all-tags | ${exe pkgs.jq} --unbuffered -r '
            .all_tags[0].tags
            | map(select(.is_active or .is_urgent or .client_count > 0)
                | ["壹","貳","參","肆","伍","陸","柒","捌","玖"][.index - 1] as $n
                | if .is_active then "[\($n)]"
                  elif .is_urgent then "!\($n)!"
                  else " \($n) " end)
            | "tags|string|\(join(""))\n"'
        '';

        tagBinds = lib.concatMapStrings (n: ''
          bind=SUPER,${n},view,${n},0
          bind=SUPER+CTRL,${n},tag,${n},0
        '') (map toString (lib.range 1 9));
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
            rootcolor=0x000000ff
            bordercolor=0x00000000
            focuscolor=0xffffffff
            urgentcolor=0xff5555ff
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

            exec-once=${exe pkgs.wbg} -s ~/Pictures/wallpaper
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
            bind=SUPER,d,spawn_shell,${lib.getExe' pkgs.wmenu "wmenu-run"} -f "Unifont 12"
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
          ".config/foot/foot.ini" = pkgs.writeText "foot.ini" "font=Unifont:pixelsize=16\n";

          # gtk apps (zathura, file pickers)
          ".config/gtk-3.0/settings.ini" = gtk;
          ".config/gtk-4.0/settings.ini" = gtk;

          ".config/yambar/config.yml" = (pkgs.formats.yaml { }).generate "config.yml" {
            bar = {
              location = "top";
              height = 20;
              spacing = 8;
              margin = 6;
              font = "Unifont:pixelsize=16";
              background = "00000000";
              foreground = "ffffffff";
              left = [
                {
                  script = {
                    path = "${mangoTags}";
                    content.string.text = "{tags}";
                  };
                }
              ];
              right = [
                {
                  battery = {
                    name = "BAT0";
                    # AC events land on ADP1, not BAT0: poll ("not charging" at threshold)
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

          ".config/fnott/fnott.ini" = pkgs.writeText "fnott.ini" (
            lib.generators.toINIWithGlobalSection { } {
              globalSection = {
                max-width = 400;
                selection-helper = lib.getExe pkgs.wmenu;
                background = "000000ff";
                border-color = "ffffffff";
                title-font = "Unifont:pixelsize=16";
                summary-font = "Unifont:pixelsize=16";
                body-font = "Unifont:pixelsize=16";
                default-timeout = 5;
              };
              sections.critical = {
                border-color = "ff5555ff";
                default-timeout = 0;
              };
            }
          );

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
