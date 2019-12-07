# -*- coding: utf-8 -*-
require 'erb'

class Array
  def to_mcjson(bind)
    '[' + self.map{|x| x.to_mcjson(bind) }.join(',') + ']'
  end
end

class Hash
  def to_mcjson(bind)
    '{' + self.map{|k,v| "#{k.to_mcjson(bind)}:#{v.to_mcjson(bind)}"}.join(',') + '}'
  end
end

class String
  def to_mcjson(bind)
    '"' + ERB.new(self).result(bind).gsub('"', '\"') + '"'
  end
end

class Numeric
  def to_mcjson(_)
    inspect
  end
end
