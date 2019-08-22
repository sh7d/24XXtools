# Encoding: binary
# frozen_string_literal: true

module Buspirate
  class Client
    attr_reader :mode, :interface

    def initialize(serial)
      raise ArgumentError, 'Shitty arg' unless serial.class == Serial

      @le_port = serial
      reset_binary_mode
      @mode = :bitbang
    end

    def reset_binary_mode
      20.times do
        @le_port.putc(Commands::RESET_BITBANG)
        resp = @le_port.expect(
          Responses::BITBANG_MODE, Timeouts::BINARY_RESET
        )
        return true if resp
      end

      raise 'Enter to bitbang failied'
    end

    def enter_i2c
      return true if @mode == :i2c

      @le_port.write(Commands::I2C::ENTER.chr)
      resp = @le_port.expect(
        Responses::I2C::ENTER, Timeouts::I2C::ENTER
      )
      if resp
        @mode = :i2c
        @interface = Interfaces::I2C.new(@le_port, self)
        return true
      end

      raise 'Switch to I2C failied'
    end
  end
end
