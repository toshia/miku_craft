# -*- coding: utf-8 -*-
Plugin.create :continuous_login do
  save_file = File.join(__dir__, 'count.dat')
  counter = FileTest.exist?(save_file) ? Marshal.load(File.open(save_file, &:read)) : {}

  on_join_player do |name|
    counter[name] ||= {last: Date.today - 1, count: 0}
    if Date.today != counter[name][:last]
      counter[name][:last] = Date.today
      counter[name][:count] += 1
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
                  'minecraft:diamond_hoe', 1, 0, "{display:{Lore:[\"#{days}日ログイン記念に#{name}がもらった\"]}}")
    when (days % 17) == 0
      Plugin.call(:giftbox_keep,
                  name,
                  "#{days}日記念！マインカートをプレゼント",
                  'minecraft:minecart', 1, 0, "{display:{Lore:[\"#{days}日ログイン記念に#{name}がもらった\"]}}")
    when (days % 7) == 0
      food = Matsuya.order.gsub(/[　（）]/, '　'=>'', '（'=>'(', '）'=>')')
      Plugin.call(:giftbox_keep,
                  name,
                  "#{days}日記念！#{food}をプレゼント",
                  'minecraft:rabbit_stew', 1, 0, %[{display:{Name: "#{food}",Lore:["#{days}日記念"]}}])
      Plugin.call(:giftbox_keep,
                  name,
                  nil,
                  'minecraft:mushroom_stew', 1, 0, '{display:{Name: "味噌汁"}}')
    when (days % 5) == 0
      Plugin.call(:giftbox_keep,
                  name,
                  "#{days}日記念！経験値ボトルをプレゼント",
                  'minecraft:experience_bottle', 1, 0, '')
    else
      Plugin.call(:giftbox_keep,
                  name,
                  "ログイン#{days}日目！棒をプレゼント",
                  'minecraft:stick', 1, 0, '')
    end
  end
end
