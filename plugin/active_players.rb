# -*- coding: utf-8 -*-
require 'time'
require 'set'
require_relative 'campaign/mc_json'

Plugin.create :active_players do
  defevent :active_players, prototype: [Pluggaloid::COLLECT]
  defevent :server_raw_output, prototype: [Symbol, Pluggaloid::STREAM]

  log_file_name = File.join(__dir__, 'login.log')
  log_file = File.open(log_file_name, 'ab')

  log_file.puts "#{Time.now.iso8601} boot miku_craft"

  on_boot_server do
    log_file.puts "#{Time.now.iso8601} boot server"
  end

  at_exit do
    log_file.puts "#{Time.now.iso8601} shutdown miku_craft"
    log_file.close
  end

  collection(:active_players) do |mutation|
    subscribe(:server_raw_output, :stdout).each do |line|
      case line
      when %r<\A\[\d{2}:\d{2}:\d{2}\] \[Server thread/INFO\]: (\w+) joined the game\Z>
        name = Regexp.last_match(1)
        log_file.puts "#{Time.now.iso8601} join #{name}"
        mutation.rewind do |ary|
          ary << name unless ary.include?(name)
          ary
        end
      when %r<\A\[\d{2}:\d{2}:\d{2}\] \[Server thread/INFO\]: (\w+) left the game\Z>
        name = Regexp.last_match(1)
        log_file.puts "#{Time.now.iso8601} left #{name}"
        mutation.delete(name)
      end
    end

    on_minecraft_server_crashed do
      mutation.rewind do |ary|
        ary.each do |name|
          Plugin.call(:give_wabiishi, name, ary)
        end
        log_file.puts "#{Time.now.iso8601} crash server"
        []
      end
    end
  end

  on_give_wabiishi do |name, victim|
    time = Time.now.strftime('%Y年%m月%d日 %H時%M分')
    Plugin.call(:giftbox_keep_stack,
                name,
                "#{time}頃にサーバがクラッシュしました。記念に詫び石をプレゼントします！",
                MinecraftItem::Stack.new(
                  MinecraftItem::Item.new(
                    'minecraft:flint',
                    tag: NBT.build({
                                     display: {
                                       Name: '詫び石',
                                       Lore: "ヽ('ω')ﾉ三ヽ('ω')ﾉ\n#{time}頃のクラッシュのお詫びです"
                                     },
                                     AttributeModifiers: [
                                       {
                                         AttributeName: 'generic.attack_damage',
                                         Name: 'generic.attack_damage',
                                         Amount: victim.size || 1,
                                         Operation: 0,
                                         UUID: 'MINECRAFT_UUID',
                                         Slot: 'mainhand'
                                       }
                                     ]
                                   })),
                  1)
               )
  end
end
