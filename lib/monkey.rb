# frozen_string_literal: true

# 説明
#
# バンドルにSTACKS種類のアイテムを詰めるのを延々繰り返しモンキーテストをする。
#
# 使い方
#
# このスクリプトを起動し、エラーが発生したらSTDOUTに随時表示される。
# C-cで終わり
START_COMPLEX = 2

require_relative 'minecraft_item'

require 'timeout'

$error_count = 0
$test_count = 0
def report(title, desc)
  $error_count += 1
  puts "error ##{$error_count}: #{title}"
  pp desc
end

def complex
  START_COMPLEX + $test_count / 100_000
end

at_exit do
  puts "finish."
  puts "#{$test_count} test ran, #{$error_count} errors detected."
end

loop do
  target_items = nil
  begin
    Timeout.timeout(1.0) do
      target_items = MinecraftItem::Stack::ITEM_STACK.keys.sample(rand(1..complex)).to_h do |n|
        [n, rand(1..MinecraftItem::Stack::ITEM_STACK[n])]
      end.freeze

      stacks = target_items.map do |id, amount|
        MinecraftItem::Stack.new(
          MinecraftItem::Item.new(id), amount
        )
      end

      check_table = target_items.dup
      MinecraftItem::Bundle.generate(stacks).each do |stack|
        if stack.item.local_id == 'bundle'
          stack.item.stacks.each do |ss|
            check_table[ss.item.id] -= ss.amount
          end
        else
          check_table[stack.item.id] -= stack.amount
        end
      end

      unless check_table.all? { _2.zero? }
        report('最後まで実行できたが、個数が誤っている', target_items)
      end
    end
  rescue Timeout::Error => e
    report(e.to_s, target_items)
  rescue => e
    report(e.to_s, target_items)
  end
  $test_count += 1
  puts "$test_count = #{$test_count}, complex = #{complex}" if $test_count % 100_000 == 0
end

