require "colorize"
require "yaml"

module Sixteen
  class Color
    property r : UInt8
    property g : UInt8
    property b : UInt8
    property hex : String

    def initialize(@r : UInt8, @g : UInt8, @b : UInt8)
      @hex = "#{@r.to_s(16)}#{@g.to_s(16)}#{@b.to_s(16)}"
    end

    def initialize(ctx, value)
      initialize value.as(YAML::Nodes::Scalar).value
    end

    def initialize(@hex : String)
      @r = @hex[0...2].to_u8(16)
      @g = @hex[2...4].to_u8(16)
      @b = @hex[4...6].to_u8(16)
    end

    def hex_bgr : String
      "#{@b}#{@g}#{@r}"
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
  end
end
