# Encoding:binary
# frozen_string_literal: true

module Buspirate
  module Responses
    BITBANG_MODE = 'BBIO1'
    SUCCESS = 0x01.chr

    module I2C
      ENTER = 'I2C1'
    end
  end
end
