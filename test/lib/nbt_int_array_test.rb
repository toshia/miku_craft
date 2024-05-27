# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'

describe 'NBT byte array' do
  it 'empty byte array' do
    a = NBT::NBTIntArray.new([])
    assert_equal '[I;]', a.snbt
  end

  it 'some values' do
    a = NBT::NBTIntArray.new([-1,0,1,2,3])
    assert_equal '[I;-1,0,1,2,3]', a.snbt
  end

  it 'huge value' do
    assert_raises(NBT::NBTRangeError) { NBT::NBTIntArray.new([NBT::NBTInteger::RANGE.max + 1]) }
  end
end
