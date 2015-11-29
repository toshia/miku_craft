# -*- coding: utf-8 -*-
require 'time'
require 'set'

Plugin.create :active_players do
  log_file_name = File.join(__dir__, 'login.log')
  log_file = File.open(log_file_name, 'ab')
  active_players = Set.new
  victim = Set.new

  log_file.puts "#{Time.now.iso8601} boot miku_craft"

  on_boot_server do
    log_file.puts "#{Time.now.iso8601} boot server"
  end

  at_exit do
    log_file.puts "#{Time.now.iso8601} shutdown miku_craft"
    log_file.close
  end

  on_join_player do |name|
    log_file.puts "#{Time.now.iso8601} join #{name}"
    active_players << name
    if victim.include? name
      Plugin.call(:give_wabiishi, name)
    end
  end

  on_left_player do |name|
    log_file.puts "#{Time.now.iso8601} left #{name}"
    active_players.delete name
  end

  on_minecraft_server_crashed do
    active_players.each do |player|
      Plugin.call(:left_player, player)
      victim << player
    end
    active_players.clear
    log_file.puts "#{Time.now.iso8601} crash server"
  end

  filter_active_players do |players|
    [active_players + players]
  end

  on_give_wabiishi do |name|
    Plugin.call(:minecraft_tell, name, "サーバクラッシュ記念に詫び石をプレゼント！")
    Plugin.call(:minecraft_give_item, name, 'minecraft:flint', 1, 0, '{display:{Name:"詫び石",Lore:["許してヒヤシンス"]},AttributeModifiers:[{AttributeName:"generic.attackDamage",Name:"generic.attackDamage",Amount:1,Operation:0,UUIDMost:62013,UUIDLeast:896789}]}')
    victim.delete name
  end
end
