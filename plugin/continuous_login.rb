# -*- coding: utf-8 -*-
require 'date'

Plugin.create :continuous_login do
  defevent :active_players, prototype: [Pluggaloid::COLLECT]

  save_file = File.join(__dir__, 'count.dat')
  counter = FileTest.exist?(save_file) ? Marshal.load(File.open(save_file, &:read)) : {}
  @last_check = Date.today.freeze

  subscribe(:active_players__add).each do |name|
    Plugin.call(:scan_continuous_login_bonus, name)
  end

  def daily_check(tomorrow)
    tomorrow.freeze
    Delayer.new(delay: tomorrow.to_time) do
      if tomorrow != @last_check
        @last_check = tomorrow
        collect(:active_players).each do |player_name|
          Plugin.call(:scan_continuous_login_bonus, player_name)
        end
      end
      daily_check(tomorrow + 1)
    end
  end
  daily_check(Date.today + 1)

  on_scan_continuous_login_bonus do |name|
    counter[name] ||= {last: Date.today - 1, count: 0}
    if Date.today != counter[name][:last]
      counter[name][:last] = Date.today
      counter[name][:count] += 1
      Plugin.call(:give_continuous_login_bonus, name, counter[name][:count])
    elsif ENV['DEBUG'].to_i != 0
      Plugin.call(:give_continuous_login_bonus, name, counter[name][:count])
    end
    File.open(save_file, 'wb') do |out|
      Marshal.dump(counter, out)
    end
  end

  on_give_continuous_login_bonus do |name, days|
    case
    when (days % 31) == 0
      Plugin.call(:giftbox_keep,
                  name,
                  "#{days}日記念！ダイヤのクワをプレゼント",
                  id: 'minecraft:diamond_hoe',
                  count: 1,
                  tag: {
                    display: {
                      Lore: ["#{days}日ログイン記念に#{name}がもらった"]
                    }
                  })
    when (days % 17) == 0
      Plugin.call(:giftbox_keep,
                  name,
                  "#{days}日記念！マインカートをプレゼント",
                  id: 'minecraft:minecart',
                  count: 1,# 0, "{display:{Lore:[\"#{days}日ログイン記念に#{name}がもらった\"]}}")
                  tag: {
                    display: {
                      Lore: ["#{days}日ログイン記念に#{name}がもらった"]
                    }
                  })
    when (days % 7) == 0
      food = Matsuya.order.gsub(/[　（）]/, '　'=>'', '（'=>'(', '）'=>')')
      Plugin.call(:giftbox_keep,
                  name,
                  "#{days}日記念！#{food}をプレゼント",
                  id: 'minecraft:rabbit_stew',
                  count: 1,
                  tag: {
                    display: {
                      Name: Hashie::Mash.new(text: food.to_s).to_mcjson(binding),
                      Lore:["#{days}日記念"]
                    }
                  })
      Plugin.call(:giftbox_keep,
                  name,
                  nil,
                  id: 'minecraft:mushroom_stew',
                  count: 1,
                  tag: {
                    display: {
                      Name: Hashie::Mash.new(text: '味噌汁').to_mcjson(binding)
                    }
                  })
    when (days % 5) == 0
      Plugin.call(:giftbox_keep,
                  name,
                  "#{days}日記念！経験値ボトルをプレゼント",
                  id: 'minecraft:experience_bottle',
                  count: 1)
    else
      Plugin.call(:giftbox_keep,
                  name,
                  "ログイン#{days}日目！棒をプレゼント",
                  id: 'minecraft:stick',
                  count: 1)
    end
  end
end
