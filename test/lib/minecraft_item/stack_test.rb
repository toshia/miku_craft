# frozen_string_literal: true

require_relative '../../test_config'
require_relative '../../../lib/minecraft_item'

describe 'Stack' do
  describe 'initialize' do
    it '0/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 0)
      assert_equal a, b.item
      assert_equal 0, b.amount
      assert_equal 0/64r, b.weight
    end

    it '1/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 1)
      assert_equal a, b.item
      assert_equal 1, b.amount
      assert_equal 1/64r, b.weight
    end

    it '1/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 1)
      assert_equal a, b.item
      assert_equal 1, b.amount
      assert_equal 1/64r, b.weight
    end

    it '65/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 65)
      assert_equal a, b.item
      assert_equal 65, b.amount
      assert_equal 65/64r, b.weight
    end
  end

  describe 'generate' do
    it '0/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.generate(a, 0)
      assert_empty b
    end

    it '1/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.generate(a, 1)
      assert_equal 1, b.size
      assert_equal a, b.first.item
      assert_equal 1, b.first.amount
      assert_equal 1/64r, b.first.weight
    end

    it '64/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.generate(a, 64)
      assert_equal 1, b.size
      assert_equal a, b.first.item
      assert_equal 64, b.first.amount
      assert_equal 1, b.first.weight
    end

    it '65/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.generate(a, 65)
      c, d = b
      assert_equal 2, b.size
      assert_equal a, c.item
      assert_equal 64, c.amount
      assert_equal 1, c.weight
      assert_equal a, d.item
      assert_equal 1, d.amount
      assert_equal 1/64r, d.weight
    end
  end

  describe 'partition' do
    it '0' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 64)
      assert_raises(MinecraftItem::BoundError) { b.partition(0/64r) }
    end

    it '要求量が多すぎて何もしなくていい場合' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 64)
      c, d = b.partition(64/64r)
      assert_equal 1, c.weight
      assert_nil d
    end

    it '1/64' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 64)
      c, d = b.partition(1/64r)
      assert_equal 1/64r, c.weight
      assert_equal 63/64r, d.weight
    end

    it '要求量が半端でちょうどの数が出せない場合' do
      a = MinecraftItem::Item.new('dirt')
      b = MinecraftItem::Stack.new(a, 64)
      c, d = b.partition(3/128r) # 1.5個まで
      assert_equal 1/64r, c.weight
      assert_equal 63/64r, d.weight
    end
  end
end
