# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'

describe 'NBT list' do
  it 'empty list' do
    a = NBT::NBTList.new([])
    assert_equal '[]', a.eval_snbt
  end

  it 'one list' do
    a = NBT::NBTList.new(['dirt'])
    assert_equal '["dirt"]', a.eval_snbt
  end

  it 'mixed list' do
    a = NBT::NBTList.new(['dirt', 1, 'gravel', 2])
    assert_equal '["dirt",1B,"gravel",2B]', a.eval_snbt
  end
end
