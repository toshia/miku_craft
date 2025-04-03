# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'

describe 'NBT string' do
  it 'empty string' do
    a = NBT::NBTString.new('')
    assert_equal '""', a.snbt
  end

  it 'dirt' do
    a = NBT::NBTString.new('dirt')
    assert_equal '"dirt"', a.snbt
  end

  it '大会 "特別賞" 商品' do
    a = NBT::NBTString.new('大会 "特別賞" 商品')
    assert_equal '"大会 \x22特別賞\x22 商品"', a.snbt
  end

  it 'test\'"\"' do
    a = NBT::NBTString.new('test\'')
    assert_equal '"test\x27"', a.snbt
    a = NBT::NBTString.new('test"')
    assert_equal '"test\x22"', a.snbt
    a = NBT::NBTString.new('test\'\'')
    assert_equal '"test\x27\x27"', a.snbt
    a = NBT::NBTString.new('test""')
    assert_equal '"test\x22\x22"', a.snbt
    a = NBT::NBTString.new('test\'"')
    assert_equal '"test\x27\x22"', a.snbt
    a = NBT::NBTString.new('test"\'')
    assert_equal '"test\x22\x27"', a.snbt
    a = NBT::NBTString.new('test\'"\'')
    assert_equal '"test\x27\x22\x27"', a.snbt
    a = NBT::NBTString.new('test"\'"')
    assert_equal '"test\x22\x27\x22"', a.snbt
  end

  it 'erb' do
    bind = -> {
      n = 123
      binding
    }.()
    n = 0
    a = NBT::NBTString.new('n * 2 = <%= n * 2 %>', bind:)
    assert_equal '"n * 2 = 246"', a.snbt
  end

  it 'compare' do
    a = NBT::NBTString.new('dirt')
    b = NBT::NBTString.new('dirt')
    c = NBT::NBTString.new('gravel')

    assert_equal a, b
    refute_equal a, c
  end
end
