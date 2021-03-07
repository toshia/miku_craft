# -*- coding: utf-8 -*-
require 'fileutils'

Plugin.create :giftbox do
  save_dir = File.expand_path(File.join(__dir__, '..', 'config', 'giftbox'))
  FileUtils.mkdir_p(save_dir)
  store = Moneta.new(:File, dir: File.join(save_dir, 'giftbox'))

  on_giftbox_keep do |name, message, id:, count: 1, tag: {}|
    box = store[name] || []
    box << {
      message: message,
      item: {
        name: id,
        amount: count,
        tag: tag } }
    store[name] = box
    if collect(:active_players).include?(name)
      Plugin.call(:giftbox_give, name)
    end
  end

  subscribe(:active_players__add).each do |name|
    Plugin.call(:giftbox_give, name)
  end

  on_giftbox_give do |name|
    if collect(:active_players).include?(name)
      box = store[name] || []
      unless box.empty?
        box.each do |gift|
          Plugin.call(:minecraft_tell, name, gift[:message]) if gift[:message].is_a? String
          item = gift[:item]
          tag = item[:tag]
          tag = Hashie::Mash.new(tag.to_h).to_mcjson(binding) if tag.respond_to?(:to_h)
          Plugin.call(:minecraft_give_item, name, item[:name], item[:amount], tag)
        end
        store[name] = []
      end
    end
  end
end
