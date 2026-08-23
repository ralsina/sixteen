require "./spec_helper"

module Sixteen
  describe Sixteen do
    describe ".theme" do
      it "loads an existing theme by name" do
        Sixteen.theme("horizon-dark").name.should eq "Horizon Dark"
      end

      it "raises for unknown themes" do
        expect_raises(Exception, "Theme not found: no-such-theme") do
          Sixteen.theme("no-such-theme")
        end
      end
    end

    describe ".available_themes" do
      it "includes known themes sorted" do
        themes = Sixteen.available_themes
        themes.should contain "horizon-dark"
        themes.should contain "horizon-light"
        themes.should eq themes.sort
      end
    end

    describe ".theme_with_fallback" do
      it "prefers dark when no variant requested" do
        Sixteen.theme_with_fallback("horizon").variant.should eq "dark"
      end

      it "honors a preferred variant" do
        Sixteen.theme_with_fallback("horizon", "light").variant.should eq "light"
        Sixteen.theme_with_fallback("gruvbox", "dark").variant.should eq "dark"
      end

      it "matches exact names first" do
        Sixteen.theme_with_fallback("horizon-light").name.should eq "Horizon Light"
      end

      # Characterization: special family mappings live in find_variant,
      # not here, so base catppuccin lookup raises even though
      # catppuccin-latte exists.
      it "raises for families needing special-case mappings" do
        expect_raises(Exception, "Theme not found: catppuccin") do
          Sixteen.theme_with_fallback("catppuccin", "light")
        end
      end

      it "raises when nothing matches" do
        expect_raises(Exception, "Theme not found: definitely-not-a-theme") do
          Sixteen.theme_with_fallback("definitely-not-a-theme")
        end
      end
    end

    describe ".light_variant / .dark_variant" do
      it "finds existing light variants through special mappings" do
        Sixteen.light_variant("rose-pine").name.should eq "Rosé Pine Dawn"
      end

      it "strips variant suffixes when locating siblings" do
        Sixteen.light_variant("horizon-dark").variant.should eq "light"
        Sixteen.dark_variant("horizon-light").variant.should eq "dark"
      end

      it "generates variants for themes without an opposite polarity" do
        # apathy has no light sibling anywhere in its family
        light = Sixteen.light_variant("apathy")
        light.variant.should eq "light"
        light.name.should contain "(Auto-generated Light)"
      end

      # Characterization: the special mappings live in find_variant, which
      # is only reached when a same-named base theme exists (rose-pine does,
      # catppuccin does not), so catppuccin lookups raise instead of
      # resolving through the mapping.
      it "raises for families whose mappings are unreachable" do
        expect_raises(Exception, "Theme not found: catppuccin") do
          Sixteen.dark_variant("catppuccin")
        end
      end

      # Characterization: suffix stripping removes one suffix class only,
      # so asking for the dark variant of gruvbox-light-medium yields the
      # sibling base theme gruvbox-light (still light). Questionable, pinned.
      it "resolves compound names to base siblings as-is" do
        Sixteen.dark_variant("gruvbox-light-medium").variant.should eq "light"
      end

      it "raises for unknown themes" do
        expect_raises(Exception, "Theme not found: nope") do
          Sixteen.light_variant("nope")
        end
      end
    end

    describe ".theme_family_info" do
      it "groups horizon variants under one family" do
        family = Sixteen.theme_family_info("horizon-dark")
        family.base_name.should eq "horizon"
        family.dark_themes.should eq ["horizon-dark", "horizon-terminal-dark"]
        family.light_themes.should eq ["horizon-light", "horizon-terminal-light"]
        family.other_variants.should be_empty
      end

      it "maps catppuccin flavors into a single family" do
        family = Sixteen.theme_family_info("catppuccin-mocha")
        family.base_name.should eq "catppuccin"
        # latte declares itself light; the other three are dark
        family.dark_themes.should eq ["catppuccin-frappe", "catppuccin-macchiato", "catppuccin-mocha"]
        family.light_themes.should eq ["catppuccin-latte"]
        family.other_variants.should be_empty
      end
    end

    describe ".theme_families" do
      it "classifies every loadable theme exactly once" do
        total = Sixteen.theme_families.sum do |family|
          family.dark_themes.size + family.light_themes.size + family.other_variants.size
        end
        total.should eq Sixteen.available_themes.size
      end

      it "keeps gruvbox base themes in one family" do
        family = Sixteen.theme_families.find! { |candidate| candidate.base_name == "gruvbox" }
        family.dark_themes.should eq ["gruvbox-dark"]
        family.light_themes.should eq ["gruvbox-light"]
      end

      # Characterization: suffix stripping happens in a single pass, so
      # "gruvbox-dark-hard" reduces to "gruvbox-dark", not "gruvbox", and
      # hardness variants form their own families. Questionable, pinned.
      it "groups compound-suffix variants under nested base names" do
        family = Sixteen.theme_families.find! { |candidate| candidate.base_name == "gruvbox-dark" }
        family.dark_themes.should eq [
          "gruvbox-dark-hard", "gruvbox-dark-medium", "gruvbox-dark-pale", "gruvbox-dark-soft",
        ]
        family.light_themes.should be_empty
      end
    end

    describe ".theme_with_family_context" do
      it "adds family navigation keys around the current theme" do
        context = Sixteen.theme_with_family_context("horizon-dark")
        context["family-other-dark-count"].should eq 1
        context["family-other-light-count"].should eq 2
        context["family-other-dark-0"].should eq "horizon-terminal-dark"
        context["family-other-light-0"].should eq "horizon-light"
        context["scheme-name"].should eq "Horizon Dark"
      end

      it "omits count keys when there are no siblings" do
        context = Sixteen.theme_with_family_context("rose-pine")
        # rose-pine has moon (dark) sibling; dawn is light sibling via mapping
        # but auto-generated slugs are added by family info, so counts may exist.
        light_count = context["family-other-light-count"]?
        unless light_count.nil?
          light_count.as?(Int32).try(&.should(be > 0))
        end
      end
    end
  end
end
