# frozen_string_literal: true

module MinecraftItem
  class BoundError < StandardError; end # 個数が制限を越えている、低すぎる場合
end

require_relative 'minecraft_item/item'
require_relative 'minecraft_item/stack'
require_relative 'minecraft_item/bundle'
