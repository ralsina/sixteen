require "./spec_helper"

module Sixteen
  describe Color do
    describe "#initialize from hex" do
      it "parses uppercase hex" do
        color = Color.new("#1C1E26")
        color.r.should eq 0x1C
        color.g.should eq 0x1E
        color.b.should eq 0x26
      end

      it "parses lowercase hex without #" do
        color = Color.new("efb993")
        color.r.should eq 0xEF
        color.g.should eq 0xB9
        color.b.should eq 0x93
      end
    end

    describe "#hex / #hex_bgr / #to_s" do
      it "renders zero-padded hex" do
        Color.new(0x01u8, 0x02u8, 0x03u8).hex.should eq "010203"
      end

      it "reverses channel order for bgr" do
        Color.new("#EFB993").hex_bgr.should eq "93b9ef"
      end

      it "prefixes to_s with #" do
        Color.new("#1C1E26").to_s.should eq "#1c1e26"
      end
    end

    describe "#light? / #dark?" do
      it "classifies dark background base00 as dark" do
        Color.new("#1C1E26").dark?.should be_true
      end

      it "classifies light foreground base05 as light" do
        Color.new("#CBCED0").light?.should be_true
      end

      it "treats the 384 sum threshold boundary as dark" do
        # 128 + 128 + 127 = 383 (not > 384) -> dark
        Color.new(128u8, 128u8, 127u8).dark?.should be_true
        # 128 + 128 + 129 = 385 (> 384) -> light
        Color.new(128u8, 128u8, 129u8).light?.should be_true
      end
    end

    describe "#hsl" do
      it "returns zero saturation and half luminance for mid gray" do
        _h, s, l = Color.new(128u8, 128u8, 128u8).hsl
        s.should eq 0.0
        l.should be_close(128 / 255.0, 1e-9)
      end

      it "keeps pure black at luminance 0 and white at 1" do
        Color.new(0u8, 0u8, 0u8).hsl[2].should eq 0.0
        Color.new(255u8, 255u8, 255u8).hsl[2].should eq 1.0
      end

      it "converts horizon-dark base00" do
        h, s, l = Color.new("#1C1E26").hsl
        h.should be_close(0.6333333333333333, 1e-12)
        s.should be_close(0.15151515151515152, 1e-12)
        l.should be_close(0.12941176470588234, 1e-12)
      end
    end

    describe "#lighter / #darker" do
      it "raises luminance by the given amount" do
        color = Color.new("#1C1E26")
        lighter = color.lighter(0.1)
        lighter.hsl[2].should be_close(color.hsl[2] + 0.1, 0.004)
      end

      it "clamps at the extremes" do
        white = Color.new("#FFFFFF")
        white.lighter(0.5).hsl[2].should eq 1.0
        black = Color.new("#000000")
        black.darker(0.5).hsl[2].should eq 0.0
      end

      it "does not overflow when darkening near-black colors (issue #1)" do
        color = Color.new(b: 199u8, g: 241u8, r: 251u8)
        darker = color.darker(0.2)
        darker.hex.should_not be_empty
      end

      it "preserves hue when adjusting luminance" do
        color = Color.new("#E93C58")
        color.darker(0.2).hsl[0].should be_close(color.hsl[0], 0.002)
      end

      it "stays within quantization error across the full hue circle" do
        worst_luminance_delta = 0.0
        36.times do |index|
          hue = index / 36.0
          color = Color.new(h: hue, s: 0.6, l: 0.4)
          adjusted = color.lighter(0.05)
          worst_luminance_delta = Math.max(worst_luminance_delta, (adjusted.hsl[2] - 0.45).abs)
        end
        worst_luminance_delta.should be < 0.004
      end
    end

    describe "#contrast" do
      it "is symmetric" do
        a = Color.new("#1C1E26")
        b = Color.new("#CBCED0")
        a.contrast(b).should eq b.contrast(a)
      end

      it "is never below 1" do
        Color.new("#123456").contrast(Color.new("#234567")).should be >= 1.0
      end

      it "rates pure white vs pure black at 21 (WCAG maximum)" do
        Color.new("#FFFFFF").contrast(Color.new("#000000")).should eq 21.0
      end

      it "uses WCAG relative luminance, not HSL luminance" do
        # WCAG for #E93C58 on black is ~5.25; HSL-based math reports ~12.49.
        Color.new("#E93C58").contrast(Color.new("#000000")).should be_close(5.25, 0.01)
      end

      it "matches published WCAG vectors" do
        # White on #767676 is the classic 4.54:1 AA boundary example
        Color.new("#FFFFFF").contrast(Color.new("#767676")).should be_close(4.54, 0.01)
      end
    end

    describe "#invert_for_theme" do
      it "maps a very dark color into the light range" do
        rose_pine_bg = Color.new("#191724") # luminance ~0.116
        inverted = rose_pine_bg.invert_for_theme(:light)
        inverted.hsl[2].should be > 0.75
        inverted.hex.should eq "d2d0de"
      end

      it "maps an accent color into the dark range preserving hue" do
        accent = Color.new("#E93C58") # luminance ~0.574
        inverted = accent.invert_for_theme(:dark)
        inverted.hex.should eq "bd1f38"
        inverted.hsl[2].should be < 0.5
        inverted.hsl[0].should be_close(accent.hsl[0], 0.005)
      end

      it "reduces saturation slightly more for light targets" do
        saturated = Color.new("#FF0000")
        light_inverted = saturated.invert_for_theme(:light)
        dark_inverted = saturated.invert_for_theme(:dark)
        light_inverted.hsl[1].should be_close(saturated.hsl[1] * 0.8, 0.01)
        # low-luminance reconstruction amplifies UInt8 quantization
        dark_inverted.hsl[1].should be_close(saturated.hsl[1] * 0.9, 0.02)
      end

      it "returns self for unknown targets" do
        color = Color.new("#ABCDEF")
        color.invert_for_theme(:weird).should eq color
      end
    end
  end
end
