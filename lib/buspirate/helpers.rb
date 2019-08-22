# Encoding:binary
# frozen_string_literal: true

module Buspirate
  module Helpers
    private

    def simplex_command(command, tout, ex_message)
      @le_port.write(command.chr)
      resp = @le_port.expect(Responses::SUCCESS, tout)
      return true if resp

      raise ex_message
    end
  end
end
