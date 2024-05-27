# frozen_string_literal: true

require 'json'

# アイテムタグ情報。
# display.Nameやdisplay.Lore内部はJSONにしなくても勝手にJSONにする
class MinecraftItem::Item
  attr_reader :id, :namespace, :local_id
  def initialize(id, tag: nil)
    case id.to_s.split(':', 2)
    in [namespace, local]
      @namespace = namespace
      @local_id = local
    in [local]
      @namespace = 'minecraft'
      @local_id = local
    end
    @id = "#{@namespace}:#{@local_id}".freeze
    @nbt = tag

    if tag
      sanitize_name
      sanitize_lore
      sanitize_enchantments
      sanitize_attribute_modifier
    end
  end

  def tag = @nbt

  # "item_id[component]{tag}" を返す
  def to_s
    "#{@id}#{snbt}"
  end

  # "{tag}" を返す
  def snbt
    @nbt&.snbt || ''
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
    raw_name = @nbt&.dig('display', 'Name')
    if raw_name
      JSON.parse(raw_name.to_s)
    end
  end

  private

  def sanitize_name
    # あー、ここで吸収できるならcampaign table書き換えなくてよかったかもなあ
    if name = @nbt.dig('display', 'Name')
      if name.is_a?(NBT::NBTString)
        unless /\A\[\{.+\}\]\z/.match?(name.to_s)
          # ここには本来リッチテキストを置く必要がある。
          # リッチテキストとは、フォーマットに従ったJSON配列を文字列にしたものである。
          # ↑の正規表現で雑に判定している。
          # リッチテキストフォーマットでない場合省略記法と判断し、リッチテキストフォーマット
          # にコンバートする。
          @nbt = @nbt.cow(['display', 'Name'], [{text: name, italic: false}].to_json)
        end
      else
        @nbt = @nbt.cow(['display', 'Name'], name.to_json)
      end
    end
  end

  def sanitize_lore
    if lore = @nbt.dig('display', 'Lore')
      if lore.is_a?(NBT::NBTString) # 省略記法
        # loreの省略記法の場合、文字列内に改行があったらいい感じに処理する
        # minecraftのtextが悪い感じなだけという話もある
        @nbt = @nbt.cow(
          ['display', 'Lore'],
          NBT::NBTList.new(lore.to_s.each_line.map { [{text: _1.chomp, italic: false}].to_json })
        )
      else
        #@nbt = @nbt.cow(['display', 'Lore'], NBT::NBTList.new(lore.to_enum.map(&:to_json)))
      end
    end
  end

  # エンチャントレベル0のものがあったら削除する。
  def sanitize_enchantments
    if enchs = @nbt['Enchantments']
      updated = false
      filtered = enchs.to_enum.reject do |ench|
        updated = true if ench[:lvl] == 0
      end
      if updated
        @nbt = @nbt.cow(['Enchantments'], NBT::NBTList.new(filtered))
      end
    end
  end

  def sanitize_attribute_modifier
    if attrs = @nbt['AttributeModifiers']
      updated = false
      filtered = attrs.to_enum.reject do |attr|
        case [attr[:Amount], attr[:Operation]]
        when [0, 0], [0, 1], [1, 2]
          updated = true
        end
      end
      if updated
        @nbt = @nbt.cow(['AttributeModifiers'], NBT::NBTList.new(filtered))
      end
    end
  end

end
