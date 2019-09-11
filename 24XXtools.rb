#!/usr/bin/env ruby
# Encoding: binary
# frozen_string_literal: true

require 'expect'
require 'optparse'
require 'bundler'
Bundler.require(:default)
Dir.glob('lib/**/*.rb') { |f| require_relative f }

LE_PROGRESSBAR_FORMAT = ' %t: [%B] %c/%C bytes '
le_options = {len: 16}

optparse = OptParse.new do |opts|
  opts.banner = '24XXtools - generic program for manipulating 24XX eeproms'\
              ' family memory content using buspirate'
  opts.separator "\nUsage: #{__FILE__} [options]\n"
  opts.separator 'Mandatory config:'
  opts.on(
    '-d device', '--device device', String, 'Path to buspirate device'
  ) do |device|
    dev_stat = File.stat(device).rdev rescue nil
    raise 'Connect buspirate first' unless dev_stat
    raise 'Device argument must be device' if dev_stat.zero?

    le_options[:device] = device
  end
  opts.separator "\nBuspirate config:"
  opts.on('--disable-power', 'Disable PSU') { le_options[:disable_psu] = true }
  opts.on('--disable-pull-up', 'Disable pull-up resistors') do
    le_options[:disable_pull_up] = true
  end
  opts.separator "\nEeprom config:"
  opts.on('-s size', '--size size', Integer, 'Specifies eeprom size in '\
                                    'kilobits (eg: 256 for 24LC256)') do |size|
    raise OptionParser::InvalidArgument, 'Size must be positive' unless size.positive?

    le_options[:size] = size
  end
  opts.separator "\nNon-destructive operations:"
  opts.on(
    '-o file', '--output file', String, 'Dumps eeprom content to file '\
                                      '(needs also size argument)'
  ) do |file|
    raise "File #{file} is a directory" if File.directory?(file)

    le_options[:dump_file] = file
  end
  opts.separator ''
  opts.on(
    '-e offset', '--read offset', String, 'Reads eeprom content '\
                                          'at given offset'
  ) do |offset|
    le_options[:read_offset] = case offset
                          when /^\d+$/
                            offset.to_i
                          when /^0x\h/i
                            offset.to_i(16)
                          else
                            raise OptionParser::InvalidArgument, 'Invalid offset'
                          end
  end
  opts.on('-l len', '--len len', Integer, "Specifies length in bytes to read (default: #{le_options[:len]})") do |len|
    raise OptionParser::InvalidArgument, 'Length must be positive' unless len.positive?

    le_options[:len] = len
  end
  opts.separator "\nDestructive operations:"
  opts.on('-r file', '--restore file', String, 'File from which eeprom will'\
                                               ' be restored') do |file|
    raise "File #{file} does not exist or is not a file" unless File.file?(file)

    le_options[:read_file] = file
  end
  opts.on('-w', '--wipe', 'Wipe eeprom memory content'\
                          '(needs also size argument)') { le_options[:wipe] = true }
  opts.separator "\nBuspirate config options:"
  opts.separator 'Other:'
  opts.on_tail('-h', '--help', 'Shows this message') do
    puts opts.to_s
    exit
  end
end
operations_bool = operations = nil
begin
  optparse.parse!
  le_options.freeze
  if le_options.size == 1
    puts optparse.to_s
    exit
  end
  raise 'Device argument is mandatory' unless le_options[:device]

  operations = [
    le_options[:read_file], le_options[:dump_file], le_options[:wipe], le_options[:read_offset]
  ].freeze
  operations_bool = operations.map { |h| !h.nil? }
  op_bad = operations_bool.select { |a| a == true }.size > 1
  raise 'Dump, restore, wipe, read options cannot be used together' if op_bad
  raise 'Dump option needs to be used with size argument' if le_options[:dump_file] && !le_options[:size]
  raise 'Restore option cannot be used with size argument' if le_options[:read_file] && le_options[:size]
  raise 'Wipe option needs to be used with size argument' if le_options[:wipe] && !le_options[:size]
  raise 'Read option needs to be used with size argument' if le_options[:read_offset] && !le_options[:size]
  raise 'Read offset outside memory boundaries' if le_options[:read_offset] && le_options[:size]*128 < (le_options[:len] + le_options[:read_offset])
rescue OptionParser::InvalidArgument => e
  puts e
  exit(1)
rescue OptionParser::MissingArgument
  puts optparse.to_s
  exit
rescue RuntimeError => e
  puts e
  exit(2)
end

if operations_bool.inject(true) { |f, k| f || k }
  buspirate_port = begin
                     SerialPort.new(
                       le_options[:device],
                       115_200,
                       8,
                       1,
                       SerialPort::NONE
                     )
                   rescue StandardError => e
                     puts 'Unable to open serial port: ' + e
                   end
  buspirate_port.flow_control = SerialPort::NONE
  buspirate_client = begin
                       Buspirate::Client.new(buspirate_port)
                     rescue RuntimeError => e
                       puts 'Unable to initialize buspirate: ' + e
                       exit(4)
                     end
  le_size = le_options[:size]
  le_size = (File.size(le_options[:read_file]) + 1) / 128 if le_options[:read_file]
  eeprom = begin
             Eeprom24XX::Memory.new(
               buspirate_client, le_size, speed: :'400khz',
               power: !le_options[:disable_psu],
               pullup: !le_options[:disable_pull_up]
             )
           rescue ArgumentError => e
             puts e.message
             exit(5)
           rescue RuntimeError => e
             puts 'Unable to configure buspirate i2c mode: ' + e.message
           end
  begin
    if le_options[:dump_file]
      pg = ProgressBar.create(
        title: 'Dumping', total: eeprom.max_position,
        format: LE_PROGRESSBAR_FORMAT
      )

      File.open(le_options[:dump_file], 'wb') do |dump_file|
        eeprom.read(eeprom.max_position, chunk_size: 1024) do |chunk|
          dump_file.write(chunk)
          pg.progress += chunk.bytesize
        end
      end

    end
    if le_options[:read_file]
      pg = ProgressBar.create(
        title: 'Restoring', total: eeprom.max_position,
        format: LE_PROGRESSBAR_FORMAT
      )
      File.open(le_options[:read_file], 'r') do |read_file|
        while (wrtdata = read_file.read(eeprom.page_size))
          eeprom.write(wrtdata) do |chunk|
            pg.progress += chunk.bytesize
          end
        end
      end
    end
    if le_options[:wipe]
      pg = ProgressBar.create(
        title: 'Wiping', total: eeprom.max_position,
        format: LE_PROGRESSBAR_FORMAT
      )
      eeprom.write("\xFF" * eeprom.max_position) do |chunk|
        pg.progress += chunk.bytesize
      end
    end
    if le_options[:read_offset]
      hexdumper = Hexdump::Dumper.new(startpos: le_options[:read_offset], chunk_size: 16)
      eeprom.seek(le_options[:read_offset])
      eeprom.read(le_options[:len], chunk_size: 16) do |chunk|
        hexdumper.dump(chunk)
      end
    end
  rescue RuntimeError => e
    puts "\nDevice communication error: " + e.message
    exit(6)
  rescue IOError => e
    puts "\nFile error: " + e.message
    exit(7)
  ensure
    eeprom.deconfigure
    buspirate_port.close
  end
else
  puts optparse.to_s
end
