# -*- coding: utf-8 -*-
Plugin.create :meshiuma do
  on_join_player do |name|
    puts "#{name} さんがログインしました"
  end

  on_left_player do |name|
    puts "#{name} さんがログアウトしました"
  end

  on_die do |name|
    Plugin.call :minecraft_execute, name, "summon FireworksRocketEntity ~ ~ ~ {LifeTime:20,FireworksItem:{id:401,Count:1,tag:{Fireworks:{Explosions:[{Type:4,Flicker:0,Trail:0,Colors:[16712965,16774912],FadeColors:[16777215]},{Type:2,Flicker:0,Trail:0,Colors:[16777215],FadeColors:[16777215]}]}}}}"
    #"execute #{name} ~ ~ ~ summon FireworksRocketEntity ~ ~ ~ {LifeTime:20,FireworksItem:{id:401,Count:1,tag:{Fireworks:{Explosions:[{Type:4,Flicker:0,Trail:0,Colors:[16712965,16774912],FadeColors:[16777215]},{Type:2,Flicker:0,Trail:0,Colors:[16777215],FadeColors:[16777215]}]}}}}"
  end
end
