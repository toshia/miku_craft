# frozen_string_literal: true

require_relative '../../test_config'
require_relative '../../../lib/nbt'
require_relative '../../../lib/minecraft_item'

describe 'Minecraft Item' do
  describe 'id' do
    it 'minecraft:dirt' do
      item = MinecraftItem::Item.new('minecraft:dirt')
      assert_equal 'minecraft:dirt', item.id
      assert_equal 'minecraft', item.namespace
      assert_equal 'dirt', item.local_id
    end

    it 'dirt' do
      item = MinecraftItem::Item.new('dirt')
      assert_equal 'minecraft:dirt', item.id
      assert_equal 'minecraft', item.namespace
      assert_equal 'dirt', item.local_id
    end
  end

  describe 'Name' do
    it '省略されていない' do
      nbt = NBT.build(
        { 'custom_name' => [{text: 'foobar', italic: false}] }
      )
      item = MinecraftItem::Item.new('dirt', component: nbt)

      assert_equal '[custom_name="[{\"text\":\"foobar\",\"italic\":false}]"]', item.component_string
      assert_equal 'foobar', item.display_name.dig(0, 'text')
      assert_equal false, item.display_name.dig(0, 'italic')
    end

    it '省略記法(string)' do
      nbt = NBT.build(
        { 'custom_name' => 'foobar' }
      )
      item = MinecraftItem::Item.new('dirt', component: nbt)

      assert_equal '[custom_name="[{\"text\":\"foobar\",\"italic\":false}]"]', item.component_string
      assert_equal 'foobar', item.display_name.dig(0, 'text')
      assert_equal false, item.display_name.dig(0, 'italic')
    end
  end

  describe 'Lore' do
    it '省略されていない' do
      nbt = NBT.build({
                        'lore' => [
                          [{text: 'line 1', italic: false}],
                          [{text: 'line 2', italic: false}]]
                      })
      item = MinecraftItem::Item.new('dirt', component: nbt)

      assert_equal '[lore=["[{\"text\":\"line 1\",\"italic\":false}]","[{\"text\":\"line 2\",\"italic\":false}]"]]', item.component_string
    end

    it '省略記法(string)' do
      nbt = NBT.build({ 'lore' => "五月雨を\n集めてはやし\n最上川" })
      item = MinecraftItem::Item.new('dirt', component: nbt)

      assert_equal '[lore=["[{\"text\":\"五月雨を\",\"italic\":false}]","[{\"text\":\"集めてはやし\",\"italic\":false}]","[{\"text\":\"最上川\",\"italic\":false}]"]]', item.component_string
    end

  end

  describe 'Enchantments' do
    it 'レベル0エンチャントが削除される' do
      nbt = NBT.build(
        {
          enchantments: {
            levels: {
              aqua_affinity: 1,
              riptide: 0
            }
          }
        }
      )
      item = MinecraftItem::Item.new('dirt', component: nbt)

      assert_equal '[enchantments={levels:{aqua_affinity:1B}}]', item.component_string
    end
  end

  describe 'AttributeModifiers' do
    it '変化量0のAttributeModifiersが削除される' do
      nbt = NBT.build(
        {
          attribute_modifiers: {
            modifiers: [
              { amount: 0, operation: 'add_value', name: '+0' },
              { amount: 1, operation: 'add_value', name: '+1' },
              { amount: 0, operation: 'add_multiplied_total', name: '+(N*0)' },
              { amount: 1, operation: 'add_multiplied_total', name: '+(N*1)' },
              { amount: 0, operation: 'add_multiplied_base', name: '*0' },
              { amount: 1, operation: 'add_multiplied_base', name: '*1' },
            ]
          }
        }
      )
      item = MinecraftItem::Item.new('dirt', component: nbt)
      a = item.component.dig(:attribute_modifiers, :modifiers).to_a
      b = Set.new(a) { _1[:name].to_s }
      assert_equal Set['+1', '+(N*1)', '*0'], b
    end

    it '動的要素は計算後の値を参照してattribute_modifiersが削除される' do
      nbt = NBT.build(
        {
          attribute_modifiers: {
            modifiers: [
              { amount: {
                  _type: 'byte',
                  value: '0'
                },
                operation: {
                  _type: 'auto',
                  value: '"add_value"'
                },
                name: 'a'
              },
              { amount: {
                  _type: 'byte',
                  value: '1'
                },
                operation: {
                  _type: 'auto',
                  value: '"add_value"'
                },
                name: 'b'
              }
            ]
          }
        },
        bind: binding
      )
      item = MinecraftItem::Item.new('dirt', component: nbt)
      a = item.component.dig(:attribute_modifiers, :modifiers).to_a
      b = Set.new(a) { _1[:name].to_s }
      assert_equal Set['b'], b
    end
  end
end
