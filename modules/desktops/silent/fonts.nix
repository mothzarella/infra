# bitmap fonts at 16px for the bar, CJK tags cut from Ark Pixel
{
  aspects.silent.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.silent.theme) cjkFont tags;
    in
    {
      fonts.packages = [
        pkgs.unifont
        pkgs.noto-fonts-color-emoji # no default fonts here, emoji are tofu otherwise
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
}
