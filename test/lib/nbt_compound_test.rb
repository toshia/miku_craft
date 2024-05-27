# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'

describe 'NBT compound' do
  it 'empty compound' do
    a = NBT::NBTCompound.new({})
    assert_equal '{}', a.snbt
  end

  it 'simple' do
    a = NBT::NBTCompound.new({a: 1, b: 2})
    assert_equal '{a:1B,b:2B}', a.snbt
  end

  it 'complex' do
    a = NBT::NBTCompound.new({1 => "dirt", "名前": "土"})
    assert_equal '{1:"dirt","名前":"土"}', a.snbt
  end

  describe '[]' do
    it 'take value' do
      a = NBT::NBTCompound.new({a: 1})
      b = a['a']
      assert_equal '1B', b.snbt
    end

    it 'key does not exists' do
      a = NBT::NBTCompound.new({})
      b = a['a']
      assert_nil b
    end
  end

  describe 'dig' do
    it 'take value' do
      a = NBT::NBTCompound.new({a: 1})
      b = a.dig('a')
      assert_equal '1B', b.snbt
    end

    it 'key does not exists' do
      a = NBT::NBTCompound.new({})
      b = a.dig('a')
      assert_nil b
    end

    it 'nested key' do
      a = NBT::NBTCompound.new({a: {b: {c: 1}}})
      b = a.dig(%w[a b c])
      c = a.dig(%w[a b])
      d = a.dig(%w[a])
      assert_equal '1B', b.snbt
      assert_equal '{c:1B}', c.snbt
      assert_equal '{b:{c:1B}}', d.snbt
    end
  end

  describe 'cow' do
    it 'key create' do
      a = NBT::NBTCompound.new({})
      b = a.cow(%w[a], 1)
      assert_equal '{a:1B}', b.snbt
      assert_equal '{}', a.snbt
    end

    it 'key update' do
      a = NBT::NBTCompound.new({a: 1})
      b = a.cow(%w[a], 2)
      assert_equal '{a:2B}', b.snbt
      assert_equal '{a:1B}', a.snbt
    end

    it 'nested compound' do
      a = NBT::NBTCompound.new({a: {b: {c: 1}}})
      b = a.cow(%w[a b c], 2)
      assert_equal '{a:{b:{c:2B}}}', b.snbt
      assert_equal '{a:{b:{c:1B}}}', a.snbt
    end

    it 'integer key' do
      a = NBT::NBTCompound.new({})
      assert_raises(NBT::TypeError) { a.cow([1], 2) }
      assert_equal '{}', a.snbt
    end

    it 'invalid hierarchy' do
      a = NBT::NBTCompound.new({})
      assert_raises(NBT::KeyError) { a.cow(%w[a b], 2) }
      assert_equal '{}', a.snbt
    end
  end
end
