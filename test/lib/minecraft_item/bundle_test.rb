# frozen_string_literal: true

require_relative '../../test_config'
require_relative '../../../lib/minecraft_item'

describe 'Bundle' do
  describe 'initialize' do
    it 'empty' do
      c = MinecraftItem::Bundle.new
      assert_empty c.stacks
    end

    it '0/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 0)
      c = MinecraftItem::Bundle.new([b])
      assert_equal 1, c.stacks.size
      assert_equal 0, c.bundle_inner_weight
    end

    it '65/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.generate(a, 65)
      c = MinecraftItem::Bundle.new(b)
      assert_equal 2, c.stacks.size
      assert_equal 65/64r, c.bundle_inner_weight
    end
  end

  describe 'append_stacks' do
    it '空を入れる' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 0)
      c = MinecraftItem::Bundle.new
      d, e = c.append_stack(b)
      assert_empty c.stacks
      assert_empty d.stacks
      assert_nil e
    end

    it '1/64を入れる' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 1)
      c = MinecraftItem::Bundle.new
      d, e = c.append_stack(b)
      assert_empty c.stacks
      assert_equal 1, d.stacks.size
      assert_equal 1/64r, d.bundle_inner_weight
      assert_equal 'minecraft:dirt', d.stacks.first.item.id
      assert_nil e
    end

    it '64/64と1/64を入れる' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 65)
      c = MinecraftItem::Bundle.new
      d, e = c.append_stack(b)
      assert_empty c.stacks
      assert_equal 1, d.stacks.size
      assert_equal 1, d.bundle_inner_weight
      assert_equal 'minecraft:dirt', d.stacks.first.item.id
      assert_equal 1, e.amount
    end

    it 'もともと内容物があるところに入れる' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 32)
      c = MinecraftItem::Bundle.new([b])
      d = MinecraftItem::Item.new('stone')
      e = MinecraftItem::Stack.new(a, 16)
      f, g = c.append_stack(e)
      assert_equal 1, c.stacks.size
      assert_equal 'minecraft:dirt', c.stacks.first.item.id
      assert_equal 1/2r, c.bundle_inner_weight
      assert_equal 2, f.stacks.size
      assert_equal 3/4r, f.bundle_inner_weight
      assert_nil g
    end


    it 'もともと内容物があるところに入れて、溢れる' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 48)
      c = MinecraftItem::Bundle.new([b])
      d = MinecraftItem::Item.new('stone')
      e = MinecraftItem::Stack.new(a, 32)
      f, g = c.append_stack(e)
      assert_equal 1, c.stacks.size
      assert_equal 'minecraft:dirt', c.stacks.first.item.id
      assert_equal 3/4r, c.bundle_inner_weight
      assert_equal 2, f.stacks.size
      assert_equal 1, f.bundle_inner_weight
      assert_equal 1/4r, g.weight
    end
  end

  describe 'generate' do
    it '空のスタックリスト' do
      a = MinecraftItem::Bundle.generate([])
      assert_empty a
    end

    it 'dirt 1' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 1)
      c = MinecraftItem::Bundle.generate([b])
      assert_equal 1, c.size
      assert_instance_of MinecraftItem::Item, c.first.item
    end

    it 'dirt 1 and stone 1' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 1)
      c = MinecraftItem::Item.new('stone')
      d = MinecraftItem::Stack.new(c, 1)
      e = MinecraftItem::Bundle.generate([b, d])
      assert_equal 1, e.size
      bundle = e.first.item
      assert_instance_of MinecraftItem::Bundle, bundle
      assert_equal 2/64r, bundle.bundle_inner_weight
      in_items = bundle.stacks.map { _1.item.id }
      assert_includes in_items, 'minecraft:dirt'
      assert_includes in_items, 'minecraft:stone'
    end

    it 'dirt 48 and stone 48 and gravel 32' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 48)
      c = MinecraftItem::Item.new('stone')
      d = MinecraftItem::Stack.new(c, 48)
      e = MinecraftItem::Item.new('gravel')
      f = MinecraftItem::Stack.new(e, 32)
      g = MinecraftItem::Bundle.generate([b, d, f])
      assert_equal 2, g.size
      bundles = g.map(&:item)
      assert_instance_of MinecraftItem::Bundle, bundles[0]
      assert_instance_of MinecraftItem::Bundle, bundles[1]
      assert_equal 1, bundles[0].bundle_inner_weight
      assert_equal 1, bundles[1].bundle_inner_weight
      in_items = bundles.map { |b| Set.new(b.stacks) { _1.item.id } }
      assert_includes in_items, Set['minecraft:dirt', 'minecraft:gravel']
      assert_includes in_items, Set['minecraft:stone', 'minecraft:gravel']
    end

    it 'item storm' do
      a = %w[
        amethyst_block
        amethyst_cluster
        amethyst_shard
        ancient_debris
        anvil
        azalea
        bamboo
        bamboo_block
        bamboo_button
        bamboo_door
        bamboo_fence
        bamboo_fence_gate
        bamboo_mosaic
        bamboo_mosaic_slab
        bamboo_mosaic_stairs
      ].map { MinecraftItem::Item.new(_1) }
      b = a.map.with_index { |item, i| MinecraftItem::Stack.new(item, (i + 1)*4) }
      g = MinecraftItem::Bundle.generate(b)
      assert_equal 8, g.size
      bundles, items = g.partition{ _1.item.local_id == 'bundle' }
      assert_equal 1, items.size
      assert_equal 32, items.first.amount
      assert_equal 'bamboo_block', items.first.item.local_id
      assert_equal 7, bundles.size
      in_items = bundles.map { |b| Set.new(b.item.stacks) { _1.item.local_id } }
      assert_includes in_items, Set['amethyst_block', 'bamboo_mosaic_stairs']
      assert_includes in_items, Set['amethyst_cluster', 'bamboo_mosaic_slab']
      assert_includes in_items, Set['amethyst_shard', 'bamboo_mosaic']
      assert_includes in_items, Set['ancient_debris', 'bamboo_fence_gate']
      assert_includes in_items, Set['anvil', 'bamboo_fence']
      assert_includes in_items, Set['azalea', 'bamboo_door']
      assert_includes in_items, Set['bamboo', 'bamboo_button']
    end

    it 'monkey test 1' do
      a = {"minecraft:dirt"=>29, "minecraft:stone"=>48, "minecraft:gravel"=>47}
      stacks = a.map do |id, amount|
        MinecraftItem::Stack.new(
          MinecraftItem::Item.new(id), amount
        )
      end
      check_table = a.dup
      MinecraftItem::Bundle.generate(stacks).each do |stack|
        if stack.item.local_id == 'bundle'
          stack.item.stacks.each do |ss|
            check_table[ss.item.id] -= ss.amount
          end
        else
          check_table[stack.item.id] -= stack.amount
        end
      end
      assert_equal(a.transform_values { 0 }, check_table)
    end

    it 'monkey test 2' do
      a = {"minecraft:black_banner"=>5, "minecraft:dirt"=>49, "minecraft:stone"=>46}
      stacks = a.map do |id, amount|
        MinecraftItem::Stack.new(
          MinecraftItem::Item.new(id), amount
        )
      end
      check_table = a.dup
      MinecraftItem::Bundle.generate(stacks).each do |stack|
        if stack.item.local_id == 'bundle'
          stack.item.stacks.each do |ss|
            check_table[ss.item.id] -= ss.amount
          end
        else
          check_table[stack.item.id] -= stack.amount
        end
      end
      assert_equal(a.transform_values { 0 }, check_table)
    end

    it 'monkey test 3' do
      a = {"minecraft:iron_ingot"=>54, "minecraft:spruce_hanging_sign"=>3, "minecraft:bamboo_mosaic_stairs"=>61, "minecraft:cherry_boat"=>1}
      stacks = a.map do |id, amount|
        MinecraftItem::Stack.new(
          MinecraftItem::Item.new(id), amount
        )
      end
      check_table = a.dup
      MinecraftItem::Bundle.generate(stacks).each do |stack|
        if stack.item.local_id == 'bundle'
          stack.item.stacks.each do |ss|
            check_table[ss.item.id] -= ss.amount
          end
        else
          check_table[stack.item.id] -= stack.amount
        end
      end
      assert_equal(a.transform_values { 0 }, check_table)
    end

    it 'keep component' do
      a = MinecraftItem::Stack.new(
        MinecraftItem::Item.new(
          :diamond_hoe,
          component: NBT.build(
            {
              custom_name: 'ダイヤのクワ',
              lore: 'lore test'
            })
        ),
        1)
      b = MinecraftItem::Bundle.generate([a])
      assert_equal 1, b.size
      assert_equal 'diamond_hoe', b.first.item.local_id
      assert_equal a.item.component_string, b.first.item.component_string
    end
  end
end
