# Encoding:binary
# frozen_string_literal: true

module Buspirate
  module Interfaces
    class I2C
      def initialize(serial, bup)
        raise 'Bus pirate must be in i2c mode' unless bup.mode == :i2c

        @le_port = serial
      end

      def configure_peripherals(power: false, pullup: false, aux: false, cs: false)
        class_used = [power, pullup, aux, cs].map(&:class).uniq.to_set.freeze
        if class_used != [FalseClass, TrueClass].to_set
          raise ArgumentError, 'All args must be true or false'
        end

        bit_config = Commands::I2C::Config::CONF_PER
        bit_config |= Commands::I2C::Config::Peripherals::POWER if power
        bit_config |= Commands::I2C::Config::Peripherals::PULLUP if pullup
        bit_config |= Commands::I2C::Config::Peripherals::AUX if aux
        bit_config |= Commands::I2C::Config::Peripherals::CS if cs

        simplex_command(
          bit_config,
          Timeouts::SUCCESS,
          'Unable to confgure peripherals'
        )
      end

      def speed(le_speed)
        bit_speed = case le_speed
                    when :'5khz'
                      Commands::I2C::Config::Speed::S5KHZ
                    when :'50khz'
                      Commands::I2C::Config::Speed::S50KHZ
                    when :'100khz'
                      Commands::I2C::Config::Speed::S100KHZ
                    when :'400khz'
                      Commands::I2C::Config::Speed::S400KHZ
                    else
                      raise ArgumentError, 'Bad speed argument'
                    end

        simplex_command(bit_speed, Timeouts::SUCCESS, 'Unable to set speed')
      end

      def start
        simplex_command(
          Commands::I2C::Flow::START,
          Timeouts::I2C::STARTSTOP,
          'Unable to sent start bit'
        )
      end

      def stop
        simplex_command(
          Commands::I2C::Flow::STOP,
          Timeouts::I2C::STARTSTOP,
          'Unable to sent stop bit'
        )
      end

      def ack
        simplex_command(
          Commands::I2C::Flow::ACK,
          Timeouts::I2C::ACKNACK,
          'Unable to sent ack'
        )
      end

      def nack
        simplex_command(
          Commands::I2C::Flow::NACK,
          Timeouts::I2C::ACKNACK,
          'Unable to sent ack'
        )
      end

      private

      def simplex_command(command, tout, ex_message)
        @le_port.write(command.chr)
        resp = @le_port.expect(Responses::SUCCESS, tout)
        return true if resp

        raise ex_message
      end
    end
  end
end
