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
end
