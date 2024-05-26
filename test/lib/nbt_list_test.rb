# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'

describe 'NBT list' do
  it 'empty list' do
    a = NBT::NBTList.new([])
    assert_equal '[]', a.snbt
  end

  it 'one list' do
    a = NBT::NBTList.new(['dirt'])
    assert_equal '["dirt"]', a.snbt
  end

  it 'mixed list' do
    a = NBT::NBTList.new(['dirt', 1, 'gravel', 2])
    assert_equal '["dirt",1B,"gravel",2B]', a.snbt
  end

  describe 'cow' do
    it 'key create' do
      a = NBT::NBTList.new([])
      b = a.cow([0], 1)
      assert_equal '[1B]', b.snbt
      assert_equal '[]', a.snbt
    end

    it 'key update' do
      a = NBT::NBTList.new([1])
      b = a.cow([0], 2)
      assert_equal '[2B]', b.snbt
      assert_equal '[1B]', a.snbt
    end

    it 'nested compound' do
      a = NBT::NBTList.new([[[1]]])
      b = a.cow([0,0,0], 2)
      assert_equal '[[[2B]]]', b.snbt
      assert_equal '[[[1B]]]', a.snbt
    end

    it 'string key' do
      a = NBT::NBTList.new([])
      assert_raises(NBT::TypeError) { a.cow(['1'], 2) }
      assert_equal '[]', a.snbt
    end

    it 'invalid hierarchy' do
      a = NBT::NBTList.new([])
      assert_raises(NBT::KeyError) { a.cow([0, 1], 2) }
      assert_equal '[]', a.snbt
    end
  end
end
