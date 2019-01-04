# -*- coding: utf-8 -*-
require 'time'
require 'set'

Plugin.create :active_players do
  log_file_name = File.join(__dir__, 'login.log')
  log_file = File.open(log_file_name, 'ab')
  active_players = Set.new

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
  end

  on_left_player do |name|
    log_file.puts "#{Time.now.iso8601} left #{name}"
    active_players.delete name
  end

  on_minecraft_server_crashed do
    active_players.each do |player|
      Plugin.call(:left_player, player)
      Plugin.call(:give_wabiishi, name, active_players)
    end
    active_players.clear
    log_file.puts "#{Time.now.iso8601} crash server"
  end

  filter_active_players do |players|
    [active_players + players]
  end

  on_give_wabiishi do |name, victim|
    Plugin.call(:giftbox_keep,
                name,
                "#{Time.now}頃にサーバがクラッシュしました。記念に詫び石をプレゼントします！",
                id: 'minecraft:flint',
                count: 1,
                tag: {
                  display: {
                    Name:"詫び石",
                    Lore:["ヽ('ω')ﾉ三ヽ('ω')ﾉ"]
                  },
                  AttributeModifiers: [
                    {
                      AttributeName: "generic.attackDamage",
                      Name: "generic.attackDamage",
                      Amount: victim.size,
                      Operation: 0,
                      UUIDMost:62013,
                      UUIDLeast:896789
                    }
                  ]
                })
  end
end
