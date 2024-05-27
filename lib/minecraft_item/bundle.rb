# frozen_string_literal: true

require_relative '../nbt'

require 'json'

# アイテムタグ情報。
# display.Nameやdisplay.Lore内部はJSONにしなくても勝手にJSONにする
class MinecraftItem::Bundle < MinecraftItem::Item

  # _stacks_ 内部のアイテムをいくつかのバンドルにまとめる。
  # 1/1スタックのアイテムはバンドルに入らず、そのまま戻り値に含まれる。
  # @param [Enumerable<MinecraftItem::Stack>] stacks まとめるアイテムスタック
  # @return [Enumerable<MinecraftItem::Stack>] stacksをまとめた結果のバンドルと、バンドルに入れる必要がなかったアイテムのリスト
  def self.generate(stacks)
    remains = stacks.sort_by { -_1.weight }.to_a # 重い順
    directs = [] # バンドルに入れないもの
    bundles = [] # 作成したバンドル

    # step1 bundleの作成または空きbundleに詰める
    # スタックの断片化はさせない。
    while !remains.empty?
      stack = remains.shift
      i = bundles.find_index { _1.capacity >= stack.weight }
      if i                      # 既存bundleに格納できるスペースがある
        bundles[i], = bundles[i].append_stack(stack)
      else                      # 空いているbundleがない場合: 新たに作る
        bundles << new([stack])
      end
      bundles.sort_by!(&:capacity) # 空きが少ないものから順番に
    end

    # step2 小さいbundleの中身をより大きいbundleの空きに詰め替える
    # 断片化を許容する。
    if bundles.size >= 2
      i = bundles.size - 1      # 詰め替え元
      while i > 0             # 空きが多いものから反復する
        if bundles[i].full?
          i -= 1
          next
        end
        src = bundles[i]
        k = j = i - 1

        # j以前の空き容量が十分か？
        capa = 0
        while k >= 0 && capa < src.bundle_inner_weight
          capa += bundles[k].capacity
          k -= 1
        end
        break if capa < src.bundle_inner_weight

        bundles.slice!(i)
        orphans = src.stacks.sort_by(&:weight)

        # orphansを他のbundleに分配していく
        while !orphans.empty? && j >= 0
          unless bundles[j].full?
            x = orphans.pop
            bundles[j], remain = bundles[j].append_stack(x)
            orphans << remain if remain
          end
          j -= 1
        end
        # スタック数によってはどの隙間にも入らない場合があるため、余ることがある。
        # その場合はバンドルに入れずに付与する。
        directs += orphans unless orphans.empty?

        i -= 1
      end
    end

    # step3 戻り値の作成。
    directs + bundles.map do |bundle|
      stacks = bundle.stacks
      if stacks.size == 1
        stacks.first
      else
        MinecraftItem::Stack.new(bundle, 1)
      end
    end
  end

  # _append_stack_ を追加してバンドルを作成する。
  # 既に _component_ に含まれているアイテムは上書きされず、追加される。
  # 追加することでバンドルのキャパシティを越えた場合も、バンドルは作成される。
  # @param [Enumerable<MinecraftItem::Stack>] append_stacks 追加するスタック
  # @param [NBT] component アイテムコンポーネント
  def initialize(append_stacks=[], component: nil)
    native_stacks = component&.dig(:bundle_contents)
    if native_stacks || !append_stacks.empty?
      append_stacks += _stacks_by_items(native_stacks) if native_stacks
      items = append_stacks.map do |stack|
        payload = { id: stack.item.id, count: stack.amount }
        payload[:components] = stack.item.component if stack.item.component
        NBT.build(payload)
      end
      if component
        component = component.cow([:bundle_contents], items)
      else
        component = NBT.build({ bundle_contents: items })
      end
    end
    super('minecraft:bundle', component:)
  end

  # 入っているスタックを列挙する
  def stacks
    items = component&.dig(:bundle_contents)
    if items
      _stacks_by_items(items)
    else
      []
    end
  end

  # スタックをバンドルに追加した新しいバンドルを作って返す。
  # バンドルに入り切らなかったアイテムは、返す。
  # @param [MinecraftItem::Stack] newstack 追加するスタック
  # @return [MinecraftItem::Bundle, Stack|nil] _stack_ が入った新しいバンドルと、入らなかったもの
  def append_stack(newstack)
    return self if newstack.weight == 0
    raise 'bundleがいっぱい！' if full?
    took, remain = newstack.partition(1 - bundle_inner_weight)
    [self.class.new([took], component:), remain]
  end

  # バンドル内の残容量
  # rationalで返す。1/1はいっぱい
  def bundle_inner_weight = stacks.sum(&:weight)

  # 空き容量
  def capacity = 1 - bundle_inner_weight

  def full?
    bundle_inner_weight >= 1
  end

  private
  def _stacks_by_items(items)
    items.to_a.map do |payload|
      item = MinecraftItem::Item.new(payload[:id], component: payload[:components])
      MinecraftItem::Stack.new(item, payload[:count].to_i)
    end
  end
end
