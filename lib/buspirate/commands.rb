# Encoding:binary
# frozen_string_literal: true

module Buspirate
  module Commands
    RESET_BITBANG = 0b00000000

    module I2C
      ENTER = 0b00000010

      module Config
        CONF_PER = 0b01000000

        module Peripherals
          POWER = 0b00001000
          PULLUP = 0b00000100
          AUX = 0b00000010
          CS = 0b00000001
        end

        module Speed
          S5KHZ = 0b01100000
          S50KZ = 0b01100001
          S100KHZ = 0b01100010
          S400KHZ = 0b01100011
        end
      end

      module Flow
        START = 0b00000010
        STOP = 0b00000011
        ACK = 0b00000110
        NACK = 0b00000111
      end
    end
  end
end
