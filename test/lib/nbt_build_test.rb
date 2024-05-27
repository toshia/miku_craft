# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'
describe 'NBT' do
  describe 'integer' do
    it '0' do
      a = NBT.build(0)
      assert_equal '0B', a.snbt
    end

    it '0x7f' do
      a = NBT.build(0x7f)
      assert_equal '127B', a.snbt
    end

    it '0x80' do
      a = NBT.build(0x80)
      assert_equal '128S', a.snbt
    end

    it '0x7fff' do
      a = NBT.build(0x7fff)
      assert_equal '32767S', a.snbt
    end

    it '0x8000' do
      a = NBT.build(0x8000)
      assert_equal '32768', a.snbt
    end

    it '0x7fffffff' do
      a = NBT.build(0x7fffffff)
      assert_equal '2147483647', a.snbt
    end

    it '0x80000000' do
      a = NBT.build(0x80000000)
      assert_equal '2147483648L', a.snbt
    end

    it '0x7fffffffffffffff' do
      a = NBT.build(0x7fffffffffffffff)
      assert_equal '9223372036854775807L', a.snbt
    end

    it '0x8000000000000000' do
      assert_raises(NBT::TypeError) { NBT.build(0x8000000000000000) }
    end

    it '-0x80' do
      a = NBT.build(-0x80)
      assert_equal '-128B', a.snbt
    end

    it '-0x81' do
      a = NBT.build(-0x81)
      assert_equal '-129S', a.snbt
    end

    it '-0x8000' do
      a = NBT.build(-0x8000)
      assert_equal '-32768S', a.snbt
    end

    it '-0x8001' do
      a = NBT.build(-0x8001)
      assert_equal '-32769', a.snbt
    end

    it '-0x80000000' do
      a = NBT.build(-0x80000000)
      assert_equal '-2147483648', a.snbt
    end

    it '-0x80000001' do
      a = NBT.build(-0x80000001)
      assert_equal '-2147483649L', a.snbt
    end

    it '-0x8000000000000000' do
      a = NBT.build(-0x8000000000000000)
      assert_equal '-9223372036854775808L', a.snbt
    end

    it '-0x8000000000000001' do
      assert_raises(NBT::TypeError) { NBT.build(-0x8000000000000001) }
    end
  end

  describe 'float' do
    it '0' do
      a = NBT.build(0.0)
      assert_equal '0.0F', a.snbt
    end
  end

  describe 'string' do
    it do
      a = NBT.build('')
      assert_equal '""', a.snbt
    end
  end

  describe 'list' do
    it do
      a = NBT.build([])
      assert_equal '[]', a.snbt
    end
  end

  describe 'compound' do
    it do
      a = NBT.build({})
      assert_equal '{}', a.snbt
    end
  end

  describe 'hash with _type' do
    it 'byte' do
      a = NBT.build({'_type' => 'auto', 'value' => '1 + 2'})
      assert_equal '3B', a.snbt
    end

    it 'intarray' do
      a = NBT.build({'_type' => 'intarray', 'value' => '[0x0f000000, 0x0f0000ff, 0x0f00ff00, 0x0fff0000]'})
      assert_equal '[I;251658240,251658495,251723520,268369920]', a.snbt
    end
  end

  describe 'MINECRAFT_UUID' do
    it do
      a = NBT.build('MINECRAFT_UUID')
      assert_match /\A\[I;(\-?\d+,){3}(\-?\d+)\]\z/, a.snbt
    end
  end
end
