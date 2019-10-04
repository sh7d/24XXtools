#!/usr/bin/env ruby
# Encoding: binary
# frozen_string_literal: true

def satanize_offset(offset)
  case offset.to_s
  when /^\d+$/
    offset.to_i
  when /^0x\h/i
    offset.to_i(16)
  when /^$/
    0
  else
    raise(OptionParser::InvalidArgument, 'Invalid offset')
  end
end
