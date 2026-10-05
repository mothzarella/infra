{config, ...}: let
  mango = pkgs: pkgs.mango.override {enableXWayland = false;};
in {
  aspects.desktop = {
    includes = with config.aspects; [audio chromium];
    nixos = {pkgs, ...}: {
      hardware.graphics.enable = true;
      environment.systemPackages = with pkgs; [
        (mango pkgs)
        foot
        wmenu
        waylock
        grim
        slurp
        brightnessctl
        wl-clipboard-rs # wl-clipboard
        swayidle # idle lock
        wlopm # dpms
        fnott # notifications
        libnotify # notify-send
        yambar # bar
        wlsunset # night light
        wlr-randr # xrandr
      ];

      environment.sessionVariables.GRIM_DEFAULT_DIR = "$HOME/Pictures";

      preservation.preserveAt."/persistent".directories = ["/var/lib/systemd/backlight"];

      security.pam.services.waylock = {};
      fonts.packages = [pkgs.unifont];
    };

    user = {
      lib,
      pkgs,
      ...
    }: let
      mangoTags = pkgs.writeShellScript "mango-tags" ''
        ${mango pkgs}/bin/mmsg watch all-tags | ${pkgs.jq}/bin/jq --unbuffered -r '
          .all_tags[0].tags
          | map(select(.is_active or .is_urgent or .client_count > 0)
              | if .is_active then "[\(.index)]"
                elif .is_urgent then "!\(.index)!"
                else " \(.index) " end)
          | "tags|string|\(join(""))\n"'
      '';
    in {
      files.".config/mango/config.conf" = pkgs.writeText "config.conf" ''
        animations=0

        exec-once=fnott
        exec-once=wlsunset -l 41.9 -L 12.5
        exec-once=swayidle -w
        exec-once=yambar

        xkb_rules_layout=us

        bind=SUPER,Return,spawn,foot
        bind=SUPER,p,spawn_shell,wmenu-run -f "Unifont 12"
        bind=SUPER+SHIFT,l,spawn,waylock
        bind=NONE,Print,spawn,grim
        bind=SHIFT,Print,spawn_shell,grim -g "$(slurp)"
        bind=NONE,XF86MonBrightnessUp,spawn,brightnessctl s +5%
        bind=NONE,XF86MonBrightnessDown,spawn,brightnessctl s 5%-
        bind=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
        bind=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        bind=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        bind=SUPER,q,killclient,
        bind=SUPER+SHIFT,e,quit,
        bind=SUPER,r,reload_config,
        bind=SUPER,j,focusstack,next
        bind=SUPER,k,focusstack,prev
        bind=SUPER,f,togglefullscreen,
        bind=SUPER,space,togglefloating,

        bind=SUPER,1,view,1,0
        bind=SUPER,2,view,2,0
        bind=SUPER,3,view,3,0
        bind=SUPER,4,view,4,0
        bind=SUPER,5,view,5,0
        bind=SUPER,6,view,6,0
        bind=SUPER,7,view,7,0
        bind=SUPER,8,view,8,0
        bind=SUPER,9,view,9,0
        bind=SUPER+SHIFT,1,tag,1,0
        bind=SUPER+SHIFT,2,tag,2,0
        bind=SUPER+SHIFT,3,tag,3,0
        bind=SUPER+SHIFT,4,tag,4,0
        bind=SUPER+SHIFT,5,tag,5,0
        bind=SUPER+SHIFT,6,tag,6,0
        bind=SUPER+SHIFT,7,tag,7,0
        bind=SUPER+SHIFT,8,tag,8,0
        bind=SUPER+SHIFT,9,tag,9,0

        mousebind=SUPER,btn_left,moveresize,curmove
        mousebind=SUPER,btn_right,moveresize,curresize
      '';

      files.".config/foot/foot.ini" = pkgs.writeText "foot.ini" "font=Unifont:pixelsize=16\n";

      files.".config/yambar/config.yml" = (pkgs.formats.yaml {}).generate "config.yml" {
        bar = {
          location = "top";
          height = 20;
          spacing = 8;
          margin = 6;
          font = "Unifont:pixelsize=16";
          background = "000000ff";
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
                name = "BAT0"; # ls /sys/class/power_supply
                poll-interval = 30000;
                content.string.text = "{capacity}% {state}";
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

      files.".config/fnott/fnott.ini" = pkgs.writeText "fnott.ini" (lib.generators.toINIWithGlobalSection {} {
        globalSection = {
          max-width = 400;
          selection-helper = "wmenu";
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
      });

      files.".config/swayidle/config" = pkgs.writeText "swayidle" ''
        timeout 300 'waylock -fork-on-lock'
        timeout 360 'wlopm --off \*' resume 'wlopm --on \*'
        before-sleep 'waylock -fork-on-lock'
        after-resume 'wlopm --on \*'
      '';
    };
  };
}
