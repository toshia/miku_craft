# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'

describe 'NBT string' do
  it 'empty string' do
    a = NBT::NBTString.new('')
    assert_equal '""', a.eval_snbt
  end

  it 'dirt' do
    a = NBT::NBTString.new('dirt')
    assert_equal '"dirt"', a.eval_snbt
  end

  it '大会 "特別賞" 商品' do
    a = NBT::NBTString.new('大会 "特別賞" 商品')
    assert_equal '"大会 \"特別賞\" 商品"', a.eval_snbt
  end

  it 'erb' do
    n = 123
    a = NBT::NBTString.new('n * 2 = <%= n * 2 %>')
    assert_equal '"n * 2 = 246"', a.eval_snbt(binding)
  end
end
