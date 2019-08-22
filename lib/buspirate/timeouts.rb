# Encoding: binary
# frozen_string_literal: true

module Buspirate
  module Timeouts
    BINARY_RESET = 0.05
    SUCCESS = 0.1
    module I2C
      ENTER = 0.2
      STARTSTOP = 0.5
      PREPARE_WRITE = 0.1
      ACKNACK = 0.3
      READ = 1
      SLAVE_ACKNACK = 0.5
      WRITE_THEN_READ_S = 5
      WRITE_THEN_READ_D = 0.1
    end
  end
end
