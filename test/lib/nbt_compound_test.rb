# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'

describe 'NBT compound' do
  it 'empty compound' do
    a = NBT::NBTCompound.new({})
    assert_equal '{}', a.eval_snbt
  end

  it 'simple' do
    a = NBT::NBTCompound.new({a: 1, b: 2})
    assert_equal '{a:1B,b:2B}', a.eval_snbt
  end

  it 'complex' do
    a = NBT::NBTCompound.new({1 => "dirt", "名前": "土"})
    assert_equal '{1:"dirt","名前":"土"}', a.eval_snbt
  end
end
