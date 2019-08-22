# Encoding:binary
# frozen_string_literal: true

module Buspirate
  module Timeouts
    BINARY_RESET = 0.1
    SUCCESS = 0.1
    module I2C
      ENTER = 0.2
      STARTSTOP = 0.5
      ACKNACK = 0.3
    end
  end
end
