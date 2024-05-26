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
