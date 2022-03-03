# -*- coding: utf-8 -*-
Plugin.create :meshiuma do
  # Symbol ... マッチしたreasonの第一引数
  # Pluggaloid::STREAM ... 以下のキーを持ったHash
  #   player: String 死亡したプレイヤー名 (必須)
  #   assailant: String 死亡させたプレイヤー名またはMOB IDまたはMOB名
  #   weapon: String 殺害に使われた武器名
  defevent :died, prototype: [Symbol, Pluggaloid::STREAM]

  suffixes = [
    %r< using (?<weapon>[^\s]+)>,
    # %r< whilst trying to escape (?<assailant>[^\s]+)>,
    %r< to escape (?<assailant>[^\s]+)>,
    %r< whilst fighting (?<assailant>[^\s]+)>
  ]

  reasons = [
    [:arrow, %r<(?<player>[A-Za-z0-9_]+) was shot by (?<assailant>[^\s]+)>],
    [:cactus, %r<(?<player>[A-Za-z0-9_]+) was pricked to death>],
    [:drowning, %r<(?<player>[A-Za-z0-9_]+) drowned?>],
    [:elytra, %r<(?<player>[A-Za-z0-9_]+) experienced kinetic energy?>],
    [:explosions, %r<(?<player>[A-Za-z0-9_]+) blew up>],
    [:explosions, %r<(?<player>[A-Za-z0-9_]+) was blown up by (?<assailant>[^\s]+)>],
    [:intentional_game_design, %r<(?<player>[A-Za-z0-9_]+) was killed by \[Intentional Game Design\]>],
    [:falling, %r<(?<player>[A-Za-z0-9_]+) hit the ground too hard>],
    [:falling, %r<(?<player>[A-Za-z0-9_]+) fell from a high place>],
    [:falling, %r<(?<player>[A-Za-z0-9_]+) fell off a ladder>, {assailant: 'minecraft:ladder'}],
    [:falling, %r<(?<player>[A-Za-z0-9_]+) fell off some weeping vines>, {assailant: 'minecraft:weeping_vines'}],
    [:falling, %r<(?<player>[A-Za-z0-9_]+) fell off some twisting vines>, {assailant: 'minecraft:twisting_vine'}],
    [:falling, %r<(?<player>[A-Za-z0-9_]+) fell off scaffolding>, {assailant: 'minecraft:scaffolding'}],
    [:falling, %r<(?<player>[A-Za-z0-9_]+) fell while climbing>],
    [:falling, %r<(?<player>[A-Za-z0-9_]+) was impaled on a stalagmite>, {assailant: 'minecraft:pointed_dripstone'}],
    [:falling_block, %r<(?<player>[A-Za-z0-9_]+) was squashed by a falling anvil>, {assailant: 'minecraft:anvil'}],
    [:falling_block, %r<(?<player>[A-Za-z0-9_]+) was squashed by a falling block>],
    [:falling_block, %r<(?<player>[A-Za-z0-9_]+) was skewered by a falling stalactite>, {assailant: 'minecraft:dripstone'}],
    [:flame, %r<(?<player>[A-Za-z0-9_]+) went up in flames>],
    [:flame, %r<(?<player>[A-Za-z0-9_]+) burned to death>],
    [:flame, %r<(?<player>[A-Za-z0-9_]+) was burnt to a crisp>],
    [:firework, %r<(?<player>[A-Za-z0-9_]+) went off with a bang>],
    [:firework, %r<(?<player>[A-Za-z0-9_]+) went off with a bang due to a firework fired from (?<weapon_named>[^\s]+) by (?<assailant>[^\s]+)>, {weapon: 'minecraft:crossbow'}],
    [:lava, %r<(?<player>[A-Za-z0-9_]+) tried to swim in lava>],
    [:lightning, %r<(?<player>[A-Za-z0-9_]+) was struck by lightning>],
    [:magma, %r<(?<player>[A-Za-z0-9_]+) discovered the floor was lava>],
    [:magma, %r<(?<player>[A-Za-z0-9_]+) walked into danger zone due to (?<assailant>[^\s]+)>],
    [:magic, %r<(?<player>[A-Za-z0-9_]+) was killed by magic>],
    [:magic, %r<(?<player>[A-Za-z0-9_]+) was killed by (?<assailant>[^\s]+) using magic>],
    [:magic, %r<(?<player>[A-Za-z0-9_]+) was killed by (?<assailant>[^\s]+) using (?<weapon_named>[^\s]+)>],
    [:twitter, %r<(?<player>[A-Za-z0-9_]+) was frozen to death>],
    [:slain, %r<(?<player>[A-Za-z0-9_]+) was slain by (?<assailant>[^\s]+)>],
    [:fireball, %r<(?<player>[A-Za-z0-9_]+) was fireballed by (?<assailant>[^\s]+)>],
    [:bee, %r<(?<player>[A-Za-z0-9_]+) was stung to death>],
    [:wither, %r<(?<player>[A-Za-z0-9_]+) was shot by a skull from (?<assailant>[^\s]+)>],
    [:starved, %r<(?<player>[A-Za-z0-9_]+) starved to death>],
    [:suffocated, %r<(?<player>[A-Za-z0-9_]+) suffocated in a wall>],
    [:sweet_berry_bushes, %r<(?<player>[A-Za-z0-9_]+) was poked to death by a sweet berry bush>],
    [:thorn, %r<(?<player>[A-Za-z0-9_]+) was killed trying to hurt (?<assailant>[^\s]+)>],
    [:thorn, %r<(?<player>[A-Za-z0-9_]+) was killed by (?<weapon>[^\s]+) trying to hurt (?<assailant>[^\s]+)>],
    [:trident, %r<(?<player>[A-Za-z0-9_]+) was impaled by (?<assailant>[^\s]+) with (?<weapon>[^\s]+)>],
    [:void, %r<(?<player>[A-Za-z0-9_]+) fell out of the world>],
    [:void, %r<(?<player>[A-Za-z0-9_]+) didn't want to live in the same world as (?<assailant>[^\s]+)>],
    [:wither_effect, %r<(?<player>[A-Za-z0-9_]+) withered away>],
    [:else, %r<(?<player>[A-Za-z0-9_]+) died>],
  ]

  reasons.group_by { |(t, *)| t }.each do |target_type, tras|
    puts "generate #{target_type.inspect}"
    generate(:died, target_type) do |yielder|
      puts "subscribe #{tras.inspect}"
      subscribe(:server_raw_output, :stdout).each do |line|
        matched, advices = tras.lazy.filter_map { |_, r, a = {}|
          r.match(line)&.then { [_1, a] }
        }.first
        if matched
          yielder << matched_to_advice(
            advices,
            *suffixes.filter_map { _1.match(line) },
            matched
          ).freeze
        end
      end
    end
  end

  subscribe(:died, :slain).each do |advice|
    if advice[:assailant] == 'Zombie'
      player = advice[:player]
      Plugin.call(:minecraft_execute, player, "summon minecraft:zombie ~ ~ ~ {CustomName:'[{\"text\":\"#{player}\"}]',Glowing:1b,CanPickUpLoot:1b,PersistenceRequired:1b,ArmorItems:[{},{},{},{id:\"minecraft:player_head\",Count:1,tag:{SkullOwner:\"#{player}\"}}],ArmorDropChances:[0f,0f,0f,1.00f]}")
    end
  end

  def matched_to_advice(base, *matches)
    matches.inject(base) do |memo, m|
      { **memo, **m.named_captures.to_h { |k, v| [k.to_sym, v] } }
    end
  end
end
