# -*- coding: utf-8 -*-

# Event = Pluggaloid::Event
# EventListener = Pluggaloid::Listener
# EventFilter = Pluggaloid::Filter
# Plugin = Pluggaloid::Plugin

include Pluggaloid

Dir.glob(File.join(__dir__, 'plugin', '*.rb')) do |ruby|
  require_relative ruby
end
