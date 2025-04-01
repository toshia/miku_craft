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
    display_name&.to_enum&.map { |n| n['text'] }&.join
  end

  # アイテム名を、リッチテキスト形式で返す。
  # JSONパース済みのArray<Hash>を返す。
  # 例: [{"text":"a","italic":false,"underlined":true},{"text":"b","italic":false,"strikethrough":true},{"text":"c","italic":false}]
  # @return 
  def display_name = @component&.dig('custom_name')

  private

  def sanitize_name
    # あー、ここで吸収できるならcampaign table書き換えなくてよかったかもなあ
    name = @component&.dig('custom_name')
    if name&.is_a?(NBT::NBTString)
      # ここには本来リッチテキストを置く必要がある。
      # リッチテキストとは、フォーマットに従ったNBTリストである。
      @component = @component.cow(['custom_name'], [{ text: name, italic: false }])
    end
  end

  # loreの省略記法
  # loreの記法には以下の3つがある
  # ## 本来の記法
  # `[[{text:'line 1',italic:false}],[{text:'line 2',italic:false}]]`
  # Minecraftの仕様どおりの記法。
  # ## 要素単位の文字列リテラル
  # `['line 1',[{text:'line 2',italic:false}]]`
  # リストの要素に文字列が含まれる場合、{text:_1,italic:false}に置き換える。
  # ## 全部文字列リテラル
  # `"line 1\nline 2"`
  # 全てが文字列リテラルの場合、行ごとに文字列を分割して、要素単位の文字列リテラル
  # と同じように扱う。
  def sanitize_lore
    if lore = @component&.dig('lore')
      if lore.is_a?(NBT::NBTString) # 全部文字列リテラル
        @component = @component.cow(
          ['lore'],
          NBT::NBTList.new(lore.to_s.each_line.map { [{ text: _1.chomp, italic: false }] })
        )
      else
        updated = false
        new_lore = lore.to_enum.map do |line|
          # loreがリストの場合、各行について以下の方法で省略記法を判定する。
          # - リストの場合、常にJSON変換後と判定する。
          # - 文字列の場合、省略記法と判定する。
          case line
          when NBT::NBTList # 本来の記法
            line
          when NBT::NBTString # 要素単位の文字列リテラル
            updated = true
            [{ text: line.chomp, italic: false }]
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
    enchs = @component.dig('enchantments')&.to_h&.dup
    if enchs
      updated = enchs.reject! { |_, lvl| lvl == 0 }
      if updated
        @component = @component.cow(['enchantments'], NBT::NBTCompound.new(enchs))
      end
    end
  end

  def sanitize_attribute_modifier
    attrs = @component.dig('attribute_modifiers')
    if attrs
      updated = false
      filtered = attrs.to_enum.reject do |attr|
        case [attr[:amount].to_f, attr[:operation].to_s]
        when [0, 'add_value'], [0, 'add_multiplied_total'], [0, 'add_multiplied_base']
          updated = true
        end
      end
      if updated
        @component = @component.cow(['attribute_modifiers'], NBT::NBTList.new(filtered))
      end
    end
  end
end
