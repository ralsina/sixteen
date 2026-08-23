require "./spec_helper"

module Sixteen
  describe Theme do
    describe "#slug" do
      it "uses the slug property when present" do
        theme = Sixteen.theme("horizon-dark")
        theme.slug.should eq "horizon-dark"
      end

      it "derives a slug from the name, stripping accents and symbols" do
        theme = Theme.new
        theme.name = "Rosé Pine — Déjà Vu!"
        theme.slug.should eq "rose-pine--deja-vu"
      end
    end

    describe "#[]" do
      it "accepts base-prefixed keys" do
        Sixteen.theme("horizon-dark")["base00"].hex.should eq "1c1e26"
      end

      it "adds the base prefix when missing" do
        Sixteen.theme("horizon-dark")["00"].hex.should eq "1c1e26"
      end

      it "formats integer indexes as two hex digits" do
        theme = Sixteen.theme("horizon-dark")
        theme[10].hex.should eq theme["base0A"].hex
        theme[0].hex.should eq theme["base00"].hex
      end
    end

    describe "#context" do
      theme = Sixteen.theme("horizon-dark")
      context = theme.context

      it "includes scheme metadata" do
        context["scheme-name"].should eq "Horizon Dark"
        context["scheme-author"].should eq "Michaël Ball (http://github.com/michael-ball/)"
        context["scheme-slug"].should eq "horizon-dark"
        context["scheme-slug-underscored"].should eq "horizon_dark"
        context["scheme-system"].should eq "base16"
        context["scheme-variant"].should eq "dark"
        context["scheme-is-dark-variant"].should be_true
      end

      it "exposes 16 colors in every documented format (184 keys)" do
        context.size.should eq 184
      end

      it "exposes hex formats" do
        context["base00-hex"].should eq "1c1e26"
        context["base00-hex-bgr"].should eq "261e1c"
        context["base00-hex-r"].should eq "1c"
        context["base00-hex-g"].should eq "1e"
        context["base00-hex-b"].should eq "26"
      end

      it "exposes rgb formats as decimal strings" do
        context["base08-rgb-r"].should eq "233"
        context["base08-rgb-g"].should eq "60"
        context["base08-rgb-b"].should eq "88"
      end

      it "exposes dec formats as 0..1 floats" do
        context["base00-dec-r"].should eq 0x1C / 255
        context["base0A-dec-b"].should eq 0x93 / 255
      end

      it "honors a custom separator" do
        dotted = theme.context(".")
        dotted["base00.hex"].should eq "1c1e26"
        dotted["scheme.name"].should eq "Horizon Dark"
      end

      it "renders bgr for accents correctly" do
        context["base0A-hex-bgr"].should eq "93b9ef"
      end
    end

    describe "#contrasting" do
      it "returns one of the palette colors, never the input color" do
        theme = Sixteen.theme("horizon-dark")
        picked = theme.contrasting(0)
        picked.hex.should_not eq theme[0].hex
      end

      it "picks a color with at least as much contrast as any other candidate" do
        theme = Sixteen.theme("horizon-dark")
        picked = theme.contrasting(0)
        best = (0..15).max_by { |index| index == 0 ? 0.0 : theme[index].contrast(theme[0]) }
        picked.contrast(theme[0]).should be >= theme[best].contrast(theme[0]) - 1e-9
      end
    end

    describe "#invert_for_theme" do
      it "produces a light variant with auto-generated naming" do
        theme = Sixteen.theme("horizon-dark")
        inverted = theme.invert_for_theme(:light)
        inverted.variant.should eq "light"
        inverted.name.should eq "Horizon Dark (Auto-generated Light)"
        inverted.slug.should eq "horizon-dark-auto-light"
        inverted.author.should eq "Michaël Ball (http://github.com/michael-ball/) + auto-generated"
        inverted.description.should eq "Auto-generated light variant"
      end

      it "keeps system and palette size" do
        theme = Sixteen.theme("horizon-dark")
        inverted = theme.invert_for_theme(:dark)
        inverted.system.should eq "base16"
        inverted.palette.size.should eq 16
      end

      it "flips background luminance to the opposite range" do
        theme = Sixteen.theme("horizon-dark")
        inverted = theme.invert_for_theme(:light)
        inverted["base00"].hsl[2].should be > 0.5
        theme["base00"].hsl[2].should be < 0.5
      end

      it "reuses the original description when present" do
        theme = Sixteen.theme("gruvbox-dark-medium")
        inverted = theme.invert_for_theme(:light)
        if theme.description.empty?
          inverted.description.should eq "Auto-generated light variant"
        else
          inverted.description.should eq theme.description
        end
      end
    end

    describe "#term_palette / #to_s" do
      it "renders an info block including name and author" do
        text = Sixteen.theme("horizon-dark").to_s
        text.should contain "Scheme:      Horizon Dark"
        text.should contain "Author:      Michaël Ball"
        text.should contain "Variant:     dark"
        text.should contain "Palette:"
      end
    end
  end
end
