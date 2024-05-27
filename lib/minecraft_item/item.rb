# frozen_string_literal: true

require 'json'
require 'yaml'

# アイテムタグ情報。
# display.Nameやdisplay.Lore内部はJSONにしなくても勝手にJSONにする
class MinecraftItem::Item
  ITEM_STACK = YAML.safe_load_file(File.join(__dir__, '../../plugin/stack.yml'))

  attr_reader :id, :namespace, :local_id, :component

  def initialize(id, component: nil)
    case id.to_s.split(':', 2)
    in [namespace, local]
      @namespace = namespace
      @local_id = local
    in [local]
      @namespace = 'minecraft'
      @local_id = local
    end
    @id = "#{@namespace}:#{@local_id}".freeze
    @component = component

    if component
      sanitize_name
      sanitize_lore
      sanitize_enchantments
      sanitize_attribute_modifier
    end
  end

  # このアイテムが1スタックに入る数を返す
  def max_stack_size
    [(@component&.dig(:max_stack_size) || ITEM_STACK[id]).to_i, 1].max
  end
  def tag = component

  # "item_id[component]" を返す
  def to_s
    "#{@id}#{component_string}"
  end

  # "[component]" を返す
  def component_string
    if @component
      [
        '[',
        *@component.to_h.map { |k, v| "#{k}=#{v.snbt}" }.join(','),
        ']'
      ].join
    else
      ''
    end
  end

  # アイテムの表示名を返す。
  # display.nameがあればそれを返す。何もなければidを返す。
  def item_name
    display_name_plain_text || id
  end

  # アイテム名を返す。
  # テキスト装飾は欠落する。
  # 例: "abc"
  def display_name_plain_text
    display_name&.map { |n| n['text'] }&.join
  end

  # アイテム名を、リッチテキスト形式で返す。
  # JSONパース済みのArray<Hash>を返す。
  # 例: [{"text":"a","italic":false,"underlined":true},{"text":"b","italic":false,"strikethrough":true},{"text":"c","italic":false}]
  def display_name
    raw_name = @component&.dig('custom_name')
    if raw_name
      JSON.parse(raw_name.to_s)
    end
  end

  private

  def sanitize_name
    # あー、ここで吸収できるならcampaign table書き換えなくてよかったかもなあ
    if name = @component&.dig('custom_name')
      if name.is_a?(NBT::NBTString)
        unless /\A\[\{.+\}\]\z/.match?(name.to_s)
          # ここには本来リッチテキストを置く必要がある。
          # リッチテキストとは、フォーマットに従ったJSON配列を文字列にしたものである。
          # ↑の正規表現で雑に判定している。
          # リッチテキストフォーマットでない場合省略記法と判断し、リッチテキストフォーマット
          # にコンバートする。
          @component = @component.cow(['custom_name'], [{text: name, italic: false}].to_json)
        end
      else
        @component = @component.cow(['custom_name'], name.to_json)
      end
    end
  end

  # loreの省略記法
  def sanitize_lore
    if lore = @component&.dig('lore')
      if lore.is_a?(NBT::NBTString) # 省略記法1
        # loreが単一の文字列だった場合、文字列内に改行があったら行ごとに分けてそれぞれ
        # JSONにフォーマットし、それらをリストにする。
        @component = @component.cow(
          ['lore'],
          NBT::NBTList.new(lore.to_s.each_line.map { [{text: _1.chomp, italic: false}].to_json })
        )
      else
        updated = false
        new_lore = lore.to_enum.map do |line|
          # loreがリストの場合、各行について以下の方法で省略記法を判定する。
          # - 文字列の場合、常にJSON変換後と判定する。
          # - リストの場合、JSONにフォーマットする。
          if line.is_a?(NBT::NBTString)
            line
          else
            updated = true
            line.to_json
          end
        end
        if updated
          @component = @component.cow(['lore'], NBT::NBTList.new(new_lore))
        end
      end
    end
  end

  # エンチャントレベル0のものがあったら削除する。
  def sanitize_enchantments
    enchs = @component.dig('enchantments', 'levels')&.to_h&.dup
    if enchs
      updated = enchs.reject! { |_, lvl| lvl == 0 }
      if updated
        @component = @component.cow(['enchantments', 'levels'], NBT::NBTCompound.new(enchs))
      end
    end
  end

  def sanitize_attribute_modifier
    attrs = @component.dig('attribute_modifiers', 'modifiers')
    if attrs
      updated = false
      filtered = attrs.to_enum.reject do |attr|
        case [attr[:amount].to_f, attr[:operation].to_s]
        when [0, 'add_value'], [0, 'add_multiplied_total'], [1, 'add_multiplied_base']
          updated = true
        end
      end
      if updated
        @component = @component.cow(['attribute_modifiers', 'modifiers'], NBT::NBTList.new(filtered))
      end
    end
  end

end
