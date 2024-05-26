# frozen_string_literal: true

require_relative '../test_config'
require_relative '../../lib/nbt'
require_relative '../../lib/minecraft_item'

describe 'Minecraft Item' do
  describe 'Name' do
    it '省略されていない' do
      nbt = NBT.build(
        { 'display' => { 'Name' => [{text: 'foobar', italic: false}] } }
      )
      item = MinecraftItem.new('dirt', tag: nbt)

      assert_equal '{display:{Name:"[{\"text\":\"foobar\",\"italic\":false}]"}}', item.snbt
      assert_equal 'foobar', item.display_name.dig(0, 'text')
      assert_equal false, item.display_name.dig(0, 'italic')
    end

    it '省略記法(string)' do
      nbt = NBT.build(
        { 'display' => { 'Name' => 'foobar' } }
      )
      item = MinecraftItem.new('dirt', tag: nbt)

      assert_equal '{display:{Name:"[{\"text\":\"foobar\",\"italic\":false}]"}}', item.snbt
      assert_equal 'foobar', item.display_name.dig(0, 'text')
      assert_equal false, item.display_name.dig(0, 'italic')
    end
  end

  describe 'Lore' do
    it '省略されていない' do
      nbt = NBT.build(
        { 'display' => { 'Lore' => [
                           [{text: 'line 1', italic: false}],
                           [{text: 'line 2', italic: false}]] } }
      )
      item = MinecraftItem.new('dirt', tag: nbt)

      assert_equal '{display:{Lore:["[{\"text\":\"line 1\",\"italic\":false}]","[{\"text\":\"line 2\",\"italic\":false}]"]}}', item.snbt
    end

    it '省略記法(string)' do
      nbt = NBT.build(
        { 'display' => { 'Lore' => "五月雨を\n集めてはやし\n最上川" } }
      )
      item = MinecraftItem.new('dirt', tag: nbt)

      assert_equal '{display:{Lore:["[{\"text\":\"五月雨を\",\"italic\":false}]","[{\"text\":\"集めてはやし\",\"italic\":false}]","[{\"text\":\"最上川\",\"italic\":false}]"]}}', item.snbt
    end

  end

  describe 'Enchantments' do
    it 'レベル0エンチャントが削除される' do
      nbt = NBT.build(
        {
          Enchantments: [
            { lvl: 1, id: 'aqua_affinity' },
            { lvl: 0, id: 'riptide' }
          ]
        }
      )
      item = MinecraftItem.new('dirt', tag: nbt)

      assert_equal '{Enchantments:[{lvl:1B,id:"aqua_affinity"}]}', item.snbt
    end
  end

  describe 'AttributeModifiers' do
    it '変化量0のAttributeModifiersが削除される' do
      nbt = NBT.build(
        {
          AttributeModifiers: [
            { Amount: 0, Operation: 0, Name: '+0' },
            { Amount: 1, Operation: 0, Name: '+1' },
            { Amount: 0, Operation: 1, Name: '+(n*0)' },
            { Amount: 1, Operation: 1, Name: '+(n*1)' },
            { Amount: 0, Operation: 2, Name: '*0' },
            { Amount: 1, Operation: 2, Name: '*1' },
          ]
        }
      )
      item = MinecraftItem.new('dirt', tag: nbt)
      a = item.tag['AttributeModifiers'].to_a

      refute a.find { _1['Name'] == '+0' }, '+0 should delete'
      assert a.find { _1['Name'] == '+1' }, '+1 should remain'
      refute a.find { _1['Name'] == '+(n*0)' }, '+(n*0) should delete'
      assert a.find { _1['Name'] == '+(n*1)' }, '+(n*1) should remain'
      assert a.find { _1['Name'] == '*0' }, '*0 should remain'
      refute a.find { _1['Name'] == '*1' }, '*1 should delete'
    end
  end
end
