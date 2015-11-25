# -*- coding: utf-8 -*-
require 'bundler/setup'
Bundler.require(:default)

Delayer.default = Delayer.generate_class(priority: %i<high normal low>, default: :normal)

require_relative 'plugin'

while true
  Delayer.run
  sleep 0.05
end
