# Encoding: binary
# frozen_string_literal: true

require 'timeout'

module Buspirate
  module Interfaces
    class I2C
      include Helpers

      def initialize(serial, bup)
        raise 'Bus pirate must be in i2c mode' unless bup.mode == :i2c

        @le_port = serial
      end

      def configure_peripherals(
        power: false, pullup: false, aux: false, cs: false
      )
        [power, pullup, aux, cs].map(&:class).each do |cls|
          raise ArgumentError, 'All args must be true or false' unless [FalseClass, TrueClass].include?(cls)
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
        bit_speed = case le_speed.to_sym
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

      def send_start
        simplex_command(
          Commands::I2C::Flow::START,
          Timeouts::I2C::STARTSTOP,
          'Unable to sent start bit'
        )
      end

      def send_stop
        simplex_command(
          Commands::I2C::Flow::STOP,
          Timeouts::I2C::STARTSTOP,
          'Unable to sent stop bit'
        )
      end

      def send_ack
        simplex_command(
          Commands::I2C::Flow::ACK,
          Timeouts::I2C::ACKNACK,
          'Unable to sent ack'
        )
      end

      def send_nack
        simplex_command(
          Commands::I2C::Flow::NACK,
          Timeouts::I2C::ACKNACK,
          'Unable to sent ack'
        )
      end

      def read(bytes = 1, auto_ack: true, auto_nack: true)
        result = ''.dup.b
        bytes.times do |t|
          @le_port.write(Commands::I2C::READBYTE.chr)
          Timeout.timeout(Timeouts::I2C::READ) do
            result << @le_port.read(1)
          end
          send_ack if auto_ack && t + 1 != bytes
          send_nack if auto_nack && t + 1 == bytes
        end
        result
      end

      def bulk_write(data)
        raise ArgumentError, 'data must be String instance' unless data.instance_of?(String)
        raise ArgumentError, 'ack_wait must be boolean' unless [TrueClass, FalseClass].include?(ack_wait)

        if !data.instance_of?(String) || data.instance_of(String) && data.empty?
          raise ArgumentError, 'Bad data argument'
        end
        raise ArgumentError, 'Data is too long' if data.bytesize > 16

        bit_bulk_write = Commands::I2C::PREPARE_WRITE | data.bytesize - 1
        simplex_command(
          bit_bulk_write.chr,
          Timeouts::I2C::PREPARE_WRITE,
          'Unable to prepare write mode'
        )
        ack_array = []
        data.each_byte do |data_byte|
          @le_port.write(data_byte)
          result = nil
          Timeout.timeout(Timeouts::I2C::SLAVE_ACKNACK) do
            result = @le_port.read(1)
          end
          ack_result = case result.ord
                       when 0
                         :ack
                       when 1
                         :nack
                       else
                         raise 'Unknown bytewrite response'
                       end

          yield(ack_result) if block_given?
          ack_array << ack_result
        end
        ack_array.freeze
      end

      def write_then_read(
        data, expected_bytes = 0,
        succes_timeout: Timeouts::I2C::WRITE_THEN_READ_S
      )
        raise ArgumentError, 'Bad data type' unless data.instance_of?(String)
        raise ArgumentError, 'Data is too long' if data.bytesize > 4096
        raise ArgumentError, 'Bad expected_bytes type' unless expected_bytes.instance_of?(Integer)
        raise ArgumentError, 'Bad expected_bytes value' if expected_bytes.negative? || expected_bytes > 4096

        binary_command = Commands::I2C::WRITE_THEN_READ.chr +
                         [data.bytesize, expected_bytes].pack('S>S>') +
                         data
        @le_port.write(binary_command)
        result = nil
        # So fucking ugly
        begin
          Timeout.timeout(succes_timeout) do
            result = @le_port.read(1)
          end
        rescue Timeout::Error
          return false
        end

        raise 'Write failed' if result.ord.zero?
        if expected_bytes != 0
          Timeout.timeout(Timeouts::I2C::WRITE_THEN_READ_D) do
            result = @le_port.read(expected_bytes)
          end
          result
        else
          true
        end
      end
    end
  end
end
