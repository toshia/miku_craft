# -*- coding: utf-8 -*-

require "minitest/autorun"
require 'bundler/setup'
Bundler.require(:default)
Bundler.require(:test)

MikuCraftRoot = File.expand_path(File.join(__dir__, '..'))

include Pluggaloid

Delayer.default = Delayer.generate_class(priority: %i<high normal low>, default: :normal)

module Minitest::Assertions
  TESTING_PLUGIN_SLUG = :_test
  def pluggaloid_clear
    Plugin.clear!
    Event.clear!
  end

  # 全部実行してから出直せ
  def delayer_run
    while !Delayer.empty?
      Delayer.run
      sleep 0.05
    end
  end

  def plugin(&)
    Plugin.create(TESTING_PLUGIN_SLUG, &)
  end

  def assert_events(events)
    test = self
    plugin do
      events.each do |event, requirements|
        add_event(event) do |*args|
          test.assert_equal requirements.size, args.size, "Event '#{event}' requires #{requirements.size} argument(s), but given #{args.size}."
          requirements.zip(args).each_with_index do |x, index|
            req, arg = x
            test.assert_operator req, :===, arg, "Argument #{index} of Event '#{event}' assertion failed."
          end
        end
      end
    end
    delayer_run
  end

  def assert_event(event_name, message=nil)
    refute_empty _event_watch(event_name), message
  end

  def refute_event(event_name, message=nil)
    assert_empty _event_watch(event_name), message
  end

  def _event_watch(event_name)
    called = []
    Plugin.create(TESTING_PLUGIN_SLUG) do
      add_event(event_name) do |*args|
        called << args
      end
    end
    delayer_run
    called
  end
end
