# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'
describe 'NBT' do
  describe 'integral' do
    it 'snbt' do
      a = NBT::NBTByte.new(0)
      assert_equal '0B', a.snbt
    end

    it 'to_i' do
      a = NBT::NBTByte.new(0)
      assert_equal 0, a.to_i
    end

    it 'to_f' do
      a = NBT::NBTByte.new(0)
      assert_equal 0, a.to_f
    end

    it 'hash' do
      a = NBT::NBTByte.new(0)
      b = NBT::NBTByte.new(0)
      c = NBT::NBTByte.new(1)
      assert_equal a.hash, b.hash
      refute_equal a.hash, c.hash
    end

    it 'compare' do
      a = NBT::NBTByte.new(0)
      b = NBT::NBTByte.new(0)
      c = NBT::NBTByte.new(1)
      assert_equal 0, a <=> b
      assert_equal -1, a <=> c
      assert_equal 1, c <=> a
      assert a == b
      assert a < c
      assert c > b
      assert_raises(ArgumentError) { a <= '1' }
    end
  end
end
