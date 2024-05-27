# frozen_string_literal: true

class MinecraftItem::Stack
  attr_reader :item, :amount

  # newと違って、スタックサイズを越えないように、複数スタックに分ける。
  # @param [MinecraftItem] item アイテム
  # @param [Integer] amount 個数
  # @return [Enumerable<Stack>] 作成したスタックのリスト
  def self.generate(item, amount)
    capa = item.max_stack_size
    filled_count = amount / capa
    remain = amount % capa

    [
      *([new(item, capa)] * filled_count if filled_count > 0),
      *(new(item, remain) if remain > 0)
    ]
  end

  def initialize(item, amount)
    @item = item
    raise TypeError, "amount #{amount.inspect} is not a Integer" unless amount.is_a?(Integer)
    @amount = amount
  end

  def max_stack_size = item.max_stack_size
  def weight = Rational(@amount, max_stack_size)

  # このスタックをsiz以下の最大と、sizを越えるぶんで分ける。
  def partition(siz)
    raise MinecraftItem::BoundError, "siz #{siz}" unless siz > 0
    desire_amount = (max_stack_size * siz).to_i
    return self if desire_amount >= @amount
    [self.class.new(item, desire_amount), self.class.new(item, @amount - desire_amount)]
  end
end
