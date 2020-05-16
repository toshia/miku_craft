# frozen_string_literal: true

Plugin.create :windows_update do
  on_join_player do |name|
    Plugin.call(:minecraft_run_command, "execute in minecraft:the_end run fill -4 61 0 2 63 5 minecraft:stone")
  end

  on_server_raw_output do |pipe, line|
    if line.include?('That position is not loaded')
      Plugin.call(:minecraft_run_command, "execute in minecraft:the_end run fill -4 61 0 2 63 5 minecraft:stone")
    end
  end
end
