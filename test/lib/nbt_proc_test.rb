# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'

describe 'NBT' do
  describe 'proc' do
    it '0' do
      a = NBT::NBTProc.new('0', type: 'auto').nbt
      assert_equal '0B', a.snbt
    end

    it 'erb' do
      bind = -> { x = 123; binding }.()
      x = 0 # for scope test
      a = NBT::NBTProc.new('[1, x]', bind: bind, type: 'auto').nbt
      assert_equal '[1B,123B]', a.snbt
    end
  end
end
