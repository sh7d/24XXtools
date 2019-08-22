# Encoding:binary
# frozen_string_literal: true

require 'expect'
require 'bundler'
Bundler.require(:default)
Dir.glob('lib/**/*.rb') { |f| require_relative f }

buspirate_port = Serial.new(
  '/dev/buspirate',
  115_200,
  8,
  :none,
  1,
  true
)
bp = Buspirate::Client.new(buspirate_port)
bp.enter_i2c
bp.interface.configure_peripherals(power: true, pullup: true)
