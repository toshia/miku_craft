# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'

describe 'NBT byte array' do
  it 'empty byte array' do
    a = NBT::NBTByteArray.new([])
    assert_equal '[B;]', a.snbt
  end

  it 'some values' do
    a = NBT::NBTByteArray.new([-1,0,1,2,3])
    assert_equal '[B;-1B,0B,1B,2B,3B]', a.snbt
  end

  it 'huge value' do
    assert_raises(NBT::NBTRangeError) { NBT::NBTByteArray.new([NBT::NBTByte::RANGE.max + 1]) }
  end
end
