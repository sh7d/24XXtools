#!/usr/bin/env ruby
# Encoding: binary
# frozen_string_literal: true

require 'expect'
require 'optparse'
require 'bundler'
Bundler.require(:default)
Dir.glob('lib/**/*.rb') { |f| require_relative f }

LE_PROGRESSBAR_FORMAT = ' %t: [%B] %c/%C bytes '
le_options = {}

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
  opts.separator 'Eepprom operations:'
  opts.separator 'Non-destructive operations:'
  opts.on(
    '-o file', '--output file', String, 'Dumps eeprom content to file '\
                                      '(needs also size argiment)'
  ) do |file|
    raise "File #{file} is a directory" if File.directory?(file)

    le_options[:dump_file] = file
  end
  opts.on('-s size', '--size size', Integer, 'Specifies eeprom size in '\
                                    'kilobits (eg: 256 for 24LC256)') do |size|
    raise OptionParser::InvalidArgument, 'Size must be positive' unless size.positive?

    le_options[:size] = size
  end
  opts.separator 'Destructive operations:'
  opts.on('-r file', '--restore file', String, 'File from which eeprom will'\
                                               ' be restored') do |file|
    raise "File #{file} does not exist or is not a file" unless File.file?(file)

    le_options[:read_file] = file
  end
  opts.separator 'Buspirate config options:'
  opts.on('--hi-speed', 'Initialize device in hi-speed '\
                                'mode (Write unstable)') do
    le_options[:hi_speed] = true
  end
end
begin
  optparse.parse!
  if le_options.empty?
    puts optparse.to_s
    exit
  end
  raise 'Device argument is mandatory' unless le_options[:device]
  raise 'Dump and restore options cannot be used together' if le_options[:read_file] &&
                                                              le_options[:dump_file]
  raise 'Dump option need to be used with size argument' if le_options[:dump_file] && !le_options[:size]
  raise 'Restore option cannot be used with size argument' if le_options[:read_file] && le_options[:size]
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

le_options.freeze

if le_options[:dump_file] || le_options[:read_file]
  buspirate_port = begin
                     Serial.new(
                       le_options[:device],
                       115_200,
                       8,
                       :none,
                       1,
                       true
                     )
                   rescue StandardError => e
                     puts 'Unable to open serial port: ' + e
                   end
  buspirate_client = begin
                       Buspirate::Client.new(buspirate_port)
                     rescue RuntimeError => e
                       puts 'Unable to initialize buspirate: ' + e
                       exit(4)
                     end

  le_bp_speed = le_options[:hi_speed] ? :'400khz' : :'100khz'
  le_size = le_options[:size]
  le_size = (File.size(le_options[:read_file]) + 1) / 128 if le_options[:read_file]
  eeprom = begin
             Eeprom24XX::Memory.new(buspirate_client, le_size, speed: le_bp_speed)
           rescue ArgumentError => e
             puts e
             exit(5)
           rescue RuntimeError => e
             puts 'Unable to configure buspirate i2c mode: ' + e
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
