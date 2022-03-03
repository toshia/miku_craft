# -*- coding: utf-8 -*-
require 'open3'
require 'timeout'

Plugin.create :minecraft do
  defevent :server_raw_output, prototype: [Symbol, Pluggaloid::STREAM]

  mc_stdin = mc_stdout = mc_stderr = wait_thr = stdout_thread = stderr_thread = watch_thread = nil
  on_boot_server do
    mc_stdin, mc_stdout, mc_stderr, wait_thr = Open3.popen3('java -Xmx8192M -Xms1024M -jar /server.jar nogui')
    stdout_thread = Thread.new do
      generate(:server_raw_output, :stdout) do |yielder|
        mc_stdout.each(&yielder.method(:<<))
      end
    end

    stderr_thread = Thread.new do
      generate(:server_raw_output, :stderr) do |yielder|
        mc_stderr.each(&yielder.method(:<<))
      end
    end

    watch_thread = Thread.new {
      wait_thr.join
      puts "Server crashed. Restert after 10 seconds."
      [stdout_thread, stderr_thread].map(&:kill)
      [mc_stdin, mc_stdout, mc_stderr].map(&:close)
      mc_stdin = mc_stdout = mc_stderr = wait_thr = stdout_thread = stderr_thread = watch_thread = nil
      Plugin.call(:minecraft_server_crashed)
      sleep 10
      Plugin.call(:boot_server)
    }
  end

  at_exit do
    puts "Unwatch server..."
    watch_thread.kill
    puts "Saving server..."
    begin
      Timeout.timeout(10) { mc_stdin.puts "save-all" }
      puts "Saved."
    rescue Timeout::Error
      puts "Failed!"
    end
    puts "Stop server..."
    begin
      Timeout.timeout(10) { mc_stdin.puts "stop" }
      puts "Stopped."
    rescue Timeout::Error
      puts "Failed!"
    end
    [stdout_thread, stderr_thread].map(&:kill)
    [mc_stdin, mc_stdout, mc_stderr].map(&:close)
    puts "Waiting shutdown server..."
    begin
      Timeout.timeout(10) { wait_thr.join }
      puts "Shutdown."
    rescue Timeout::Error
      puts "Timeout! Send SIGKILL to minecraft server(pid: #{wait_thr.pid})."
      Process.kill(:KILL, wait_thr.pid)
      puts "Killed ##{wait_thr.pid}"
    end
    puts "bye."
  end

  on_minecraft_execute do |user_name, command|
    Plugin.call :minecraft_run_command, "execute at #{user_name} run #{command}"
  end

  on_minecraft_give_item do |user_name, item_name, count, datatag|
    Plugin.call :minecraft_run_command, "give #{user_name} #{item_name}#{datatag} #{count}"
  end

  on_minecraft_tell do |user_name, message|
    Plugin.call :minecraft_run_command, "tell #{user_name} #{message}"
  end

  on_minecraft_run_command do |command|
    puts "command run: #{command}"
    mc_stdin.puts command
  end

  subscribe(:server_raw_output, :stdout).each do |line|
    puts "stdout: #{line}"
  end

  subscribe(:server_raw_output, :stderr).each do |line|
    puts "stderr: #{line}"
  end

  Plugin.call(:boot_server)
end
