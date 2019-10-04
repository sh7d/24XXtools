# Encoding: binary
# frozen_string_literal: true

require 'stringio'

module Eeprom24XX
  class Memory
    attr_reader :pos, :configured, :max_position, :page_size

    def initialize(
          buspirate, eeprom_size, speed: :'400khz', power: true, pullup: true
        )
      raise ArgumentError, 'Bad buspirate arg' unless buspirate.instance_of?(Buspirate::Client)
      raise ArgumentError, 'Bad eeprom_size arg' unless eeprom_size.instance_of?(Integer) && !eeprom_size.negative?

      @max_position = eeprom_size.zero? ? 15 : eeprom_size * 128 - 1
      @buspirate = buspirate
      @speed = speed
      @page_size = PAGE_SIZES[eeprom_size]
      @pos = 0
      raise ArgumentError, 'Unknown eeprom size' if @page_size.nil?
      configure(power: power, pullup: pullup)
    end

    def seek(pos)
      raise ArgumentError, 'Bad pos argument' unless pos.instance_of?(Integer) && !pos.negative?
      raise ArgumentError, 'Position too big' if @pos > @max_position
      raise 'Device must be configured' unless @configured

      @pos = pos
      bit_command = generate_seeknwrite_command(pos)
      result = @buspirate.interface.write_then_read(bit_command)
      raise 'Unable to seek - bad response or timeout?' unless result

      pos
    end

    def read(bytes, chunk_size: 4096)
      raise 'Device must be configured' unless @configured
      raise ArgumentError, 'Bad chunk_size argument' unless chunk_size.instance_of?(Integer) && !chunk_size.negative?

      if @pos == @max_position
        yield nil if block_given?
        return nil
      end
      bytestream = ''.b
      loop do
        toread = (bytes - chunk_size).positive? ? chunk_size : bytes
        break if toread.zero?

        result = @buspirate.interface.write_then_read(Commands::READ.chr, toread)
        raise 'Unable to read/timeout' unless result

        (@pos + toread) > @max_position ? seek(@max_position) : seek(@pos + toread)
        bytestream << result
        bytes -= chunk_size
        yield result if block_given?
        break if bytes.negative? || @pos == @max_position
      end
      bytestream.freeze
    end

    def write(data)
      raise 'Device must be configured' unless @configured
      raise ArgumentError, 'Data too big' if @pos + data.size > @max_position
      data = StringIO.new(data)

      while (data_chunk = data.read(@page_size - @pos % @page_size))
        comm = generate_seeknwrite_command(@pos)
        comm += data_chunk
        result = @buspirate.interface.write_then_read(comm, 0)
        raise 'Unable to write - timeout/bad response?' unless result

        pos = @pos + data_chunk.size
        begin
          Timeout.timeout(Timeouts::WRITE_WAIT_TIMEOUT) do
            comm = generate_seeknwrite_command(pos)
            loop do
              result = @buspirate.interface.write_then_read(comm, 0, allow_zerobyte: true)
              break if result
            end
          end
        rescue Timeout::Error
          raise 'Unable to get write ack - timeout'
        end
        @pos = pos
        yield data_chunk if block_given?
      end
      data.size
    end

    def deconfigure
      if @configured
        @buspirate.interface.configure_peripherals(power: false, pullup: false)
        @buspirate.reset_binary_mode
        @configured = false
      end
      @configured
    end

    def configure(power:, pullup:)
      unless @configured
        @buspirate.enter_i2c
        @buspirate.interface.speed(@speed)
        @buspirate.interface.configure_peripherals(power: power, pullup: pullup)
        @configured = true
        seek(0)
      end
      @configured
    end

    private

    def generate_seeknwrite_command(pos)
      case @max_position
      when 0..2047
        [
          ((Commands::SEEKNWRITE >> 1) | pos >> 8) << 1,
          pos & 0xFF
        ].pack('CC')
      when 2048..65_535
        [Commands::SEEKNWRITE, pos].pack('CS>')
      when 65_536..262_143
        [
          (Commands::SEEKNWRITE >> 1 | pos >> 16) << 1,
          pos & 0xFFFF
        ].pack('CS>')
      end
    end
  end
end
