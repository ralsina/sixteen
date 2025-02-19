require "./spec_helper"

describe Sixteen do
  # Test for Issue #1
  it "should not overflow" do
    color = Sixteen::Color.new(b: 199u8, g: 241u8, r: 251u8)
    color.darker(0.2)
  end
end
