# -*- coding: utf-8 -*-
require 'fileutils'
require_relative '../lib/minecraft_item'

ITEM_STACK = YAML.safe_load_file(File.join(__dir__, 'stack.yml'))

Plugin.create :giftbox do
  save_dir = File.expand_path(File.join(__dir__, '..', 'config', 'giftbox'))
  FileUtils.mkdir_p(save_dir)
  store = Moneta.new(:File, dir: File.join(save_dir, 'giftbox'))

  on_giftbox_keep do |name, message, opts|
    box = store[name] || []
    box << {
      message: message,
      item: {
        name: opts[:id],           # 'minecraft:dirt'
        amount: opts[:count] || 1, # 1
        tag: opts[:tag]            # MinecraftItem::Item | nil
      }
    }
    store[name] = box
    if collect(:active_players).include?(name)
      Plugin.call(:giftbox_give, name)
    end
  end

  # @params [MinecraftItem::Stack] stack 付与するアイテム
  on_giftbox_keep_stack do |name, message, stack|
    raise "giftbox_keep_stack#stackにはMinecraftItem::Stackを渡す(#{stack.inspect}が渡された)" unless stack.is_a?(MinecraftItem::Stack)
    box = store[name] || []
    box << {
      message:,
      stack: # MinecraftItem::Stack
    }
    store[name] = box
    if collect(:active_players).include?(name)
      Plugin.call(:giftbox_give, name)
    end
  end

  subscribe(:active_players__add).each do |name|
    Plugin.call(:giftbox_give, name)
  end

  on_giftbox_give do |player_name|
    if collect(:active_players).include?(player_name)
      box = store[player_name] || []
      item_stacks = box.flat_map do |gift|
        case gift
        in {stack: MinecraftItem::Stack => stack}
          [stack]
        in {item: {name:, amount: i, tag: MinecraftItem::Item => tag}}
          MinecraftItem::Stack.generate(tag, i)
        in {item: {name: id, amount: i}}
          MinecraftItem::Stack.generate(MinecraftItem::Item.new(id), i)
        else
          warn "unknown gift payload! #{box.inspect}"
          []
        end
      end
      MinecraftItem::Bundle.generate(item_stacks).each do |stack|
        Plugin.call(:minecraft_give_item, player_name, stack.item.id, stack.amount, stack.item)
      end
      box.each do |gift|
        Plugin.call(:minecraft_tell, player_name, gift[:message]) if gift[:message].is_a? String
      end
      unless box.empty?
        store[player_name] = []
      end
    end
  end

  def calc_weight(item)
    Rational((item['Count'] || 1).to_i, ITEM_STACK[item['id'].to_s] || 1)
  end
end
