require "colorize"
require "yaml"

module Sixteen
  class Color
    property r : UInt8
    property g : UInt8
    property b : UInt8

    def initialize(@r : UInt8, @g : UInt8, @b : UInt8)
    end

    def initialize(ctx, value)
      initialize value.as(YAML::Nodes::Scalar).value
    end

    def initialize(hex : String)
      @r = hex[0...2].to_u8(16)
      @g = hex[2...4].to_u8(16)
      @b = hex[4...6].to_u8(16)
    end

    def initialize(*, h, s, l)
      if 0 == s # Achromatic
        @r = @g = @b = (l * 255).to_u8
      else
        q = l < 0.5 ? l * (1 + s) : l + s - l * s
        p = 2 * l - q
        @r = (hue2rgb(p, q, h + 1/3) * 255).to_u8
        @g = (hue2rgb(p, q, h) * 255).to_u8
        @b = (hue2rgb(p, q, h - 1/3) * 255).to_u8
      end
    end

    def lighter(amount : Float64 = 0.1)
      h, s, l = hsl
      l = (l + amount).clamp(0.0, 1.0)
      Color.new(h: h, s: s, l: l)
    end

    def darker(amount : Float64 = 0.1)
      lighter(-amount)
    end

    def hex : String
      "#{@r.to_s(16).rjust(2, '0')}#{@g.to_s(16).rjust(2, '0')}#{@b.to_s(16).rjust(2, '0')}"
    end

    def hex_bgr : String
      "#{@b.to_s(16).rjust(2, '0')}#{@g.to_s(16).rjust(2, '0')}#{@r.to_s(16).rjust(2, '0')}"
    end

    def to_s
      "##{hex}"
    end

    def colorize : Colorize::ColorRGB
      Colorize::ColorRGB.new(@r, @g, @b)
    end

    def light?
      0.0 + @r + @g + @b > 384
    end

    def dark?
      !light?
    end

    def hue2rgb(p, q, t)
      t += 1 if t < 0
      t -= 1 if t > 1
      return p + (q - p) * 6 * t if t < 1/6
      return q if t < 1/2
      p + (q - p) * (2/3 - t) * 6
    end

    def hsl
      r = @r / 255.0
      g = @g / 255.0
      b = @b / 255.0

      max = [r, g, b].max
      min = [r, g, b].min

      h = 0.0
      s = 0.0
      # Total luminance / 2
      l = (max + min) / 2.0

      if max != min
        # Luminance range
        d = max - min

        # Saturation is different for high or low luminance
        s = l > 0.5 ? d / (2.0 - max - min) : d / (max + min)

        # Hue is different for each color
        case max
        when r
          h = (g - b) / d + (g < b ? 6.0 : 0.0)
        when g
          h = (b - r) / d + 2.0
        when b
          h = (r - g) / d + 4.0
        end

        h /= 6.0
      end

      {h, s, l}
    end
  end
end
