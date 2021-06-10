# -*- coding: utf-8 -*-
require 'fileutils'

Plugin.create :giftbox do
  save_dir = File.expand_path(File.join(__dir__, '..', 'config', 'giftbox'))
  FileUtils.mkdir_p(save_dir)
  store = Moneta.new(:File, dir: File.join(save_dir, 'giftbox'))

  on_giftbox_keep do |name, message, opts|
    box = store[name] || []
    box << {
      message: message,
      item: {
        name: opts[:id],
        amount: opts[:count] || 1,
        tag: opts[:tag] || {}
      }
    }
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
      case box.size
      when 0
        next
      when 1
        case box
        in {item: {name: item_name, amount: amount, tag: tag}}
          tag = Hashie::Mash.new(tag.to_h).to_mcjson(binding) if tag.respond_to?(:to_h)
          Plugin.call(:minecraft_give_item, name, item_name, amount, tag)
        end
      when 2..
        box.map do |gift|
          case gift
              in {item: {name: item_name, amount: amount, tag: tag}}
            Hashie::Mash.new({id: item_name, Count: amount, tag: tag}).tap do
              tag = Hashie::Mash.new(tag.to_h).to_mcjson(binding) if tag.respond_to?(:to_h)
              Plugin.call(:minecraft_give_item, name, item_name, amount, tag)
            end
          end
        end.each_slice(6) do |gifts|
             Plugin.call(:minecraft_give_item, name, 'minecraft:bundle', 1,
                         Hashie::Mash.new({ Items: gifts }).to_mcjson(binding))
        end
      end

      box.each do |gift|
        Plugin.call(:minecraft_tell, name, gift[:message]) if gift[:message].is_a? String
      end

      unless box.empty?
        store[name] = []
      end
    end
  end
end
