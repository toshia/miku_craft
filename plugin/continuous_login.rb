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
    Plugin.call(:minecraft_tell, name, "ログイン#{days}日目！棒をプレゼント")
    Plugin.call(:minecraft_give_item, name, 'minecraft:stick', 1, 0, '')
    if (days % 5) == 0
      Plugin.call(:minecraft_tell, name, "#{days}日記念！経験値ボトルをプレゼント")
      Plugin.call(:minecraft_give_item, name, 'minecraft:experience_bottle', 1, 0, '')
    end
    if (days % 30) == 0
      Plugin.call(:minecraft_tell, name, "#{days}日記念！マインカートをプレゼント")
      Plugin.call(:minecraft_give_item, name, 'minecraft:minecart', 1, 0, "{display:{Lore:[\"#{days}日ログイン記念に#{name}がもらった\"]}}")
    end
    if (days % 50) == 0
      Plugin.call(:minecraft_tell, name, "#{days}日記念！ダイヤのクワをプレゼント")
      Plugin.call(:minecraft_give_item, name, 'minecraft:diamond_hoe', 1, 0, "{display:{Lore:[\"#{days}日ログイン記念に#{name}がもらった\"]}}")
    end
  end
end
