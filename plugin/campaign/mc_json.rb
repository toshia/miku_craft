# -*- coding: utf-8 -*-
require 'erb'
require 'securerandom'

class Array
  def to_mcjson(bind)
    MCJsonString.new('[' + self.map{|x| x.to_mcjson(bind) }.join(',') + ']')
  end
end

class Hash
  def to_mcjson(bind)
    if has_key?('advice') && has_key?('value')
      value = fetch('value').to_mcjson(bind)
      MCJsonString.new(JSON.parse(value).__send__(fetch('advice')).to_s)
    elsif self['_type'] == 'intarray' && has_key?('value')
      MCJsonString.new('[I;%{content}]' % { content: self['value'].map(&'%d'.method(:%)).join(',') })
    else
      MCJsonString.new('{' + self.map{|k,v| "#{k.to_mcjson(bind)}:#{v.to_mcjson(bind)}"}.join(',') + '}')
    end
  end
end

class String
  def to_mcjson(bind)
    v = ERB.new(self).result(bind)
    if v == 'MINECRAFT_UUID'
      MCJsonString.new("[I;%d,%d,%d,%d]" % SecureRandom.random_bytes(16).unpack("i4"))
    else
      MCJsonString.new('"' + v.gsub('"', '\"') + '"')
    end
  end
end

class Symbol
  def to_mcjson(bind)
    MCJsonString.new('"' + to_s.gsub('"', '\"') + '"')
  end
end

class Numeric
  def to_mcjson(_)
    MCJsonString.new(inspect)
  end
end

class MCJsonString < String
  def to_mcjson(_)
    self
  end
end
