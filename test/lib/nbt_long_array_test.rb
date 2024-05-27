# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'

describe 'NBT byte array' do
  it 'empty byte array' do
    a = NBT::NBTLongArray.new([])
    assert_equal '[L;]', a.snbt
  end

  it 'some values' do
    a = NBT::NBTLongArray.new([-1,0,1,2,3])
    assert_equal '[L;-1L,0L,1L,2L,3L]', a.snbt
  end

  it 'huge value' do
    assert_raises(NBT::NBTRangeError) { NBT::NBTLongArray.new([NBT::NBTLong::RANGE.max + 1]) }
  end
end
