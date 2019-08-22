# Encoding: binary
# frozen_string_literal: true
module Eeprom24XX
  PAGE_SIZES = {
    1024 => 256,
    512 => 128,
    256 => 64,
    64 => 32,
    32 => 8,
    16 => 16
  }.freeze
end
