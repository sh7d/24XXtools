# Encoding: binary
# frozen_string_literal: true
module Eeprom24XX
  PAGE_SIZES = {
    2048 => 256,
    1024 => 256,
    512 => 128,
    256 => 64,
    64 => 32,
    32 => 32,
    16 => 16,
    8 => 16,
    4 => 16,
    2 => 8,
    1 => 8,
    0 => 16
  }.freeze
end
