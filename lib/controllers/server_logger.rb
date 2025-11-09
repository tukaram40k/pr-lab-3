require 'time'
require 'fileutils'
require 'thread'

class ServerLogger
  attr_accessor :path

  def initialize(path)
    if path.nil? or path.to_s.strip.empty?
      raise ArgumentError, "bad logger path: #{path.inspect}"
    end

    FileUtils.mkdir_p(path)
    @path = File.join(path, "server.log")
    puts "logger will write to: #{@path.inspect}"

    @mutex = Mutex.new

    @mutex.synchronize do
      File.open(@path, 'w') do |log_file|
        log_file.truncate(0)
      end
      File.open(@path, 'a') do |log_file|
        timestamp = Time.now.strftime("[%Y-%m-%d %H:%M:%S]")
        log_file.puts "#{timestamp} started server."
      end
    end
  end

  def log_board(board_str)
    @mutex.synchronize do
      File.open(@path, 'a') do |log_file|
        timestamp = Time.now.strftime("[%Y-%m-%d %H:%M:%S]")
        log_file.puts "#{timestamp} created new board:"
        log_file.puts "#{board_str}"
      end
    end
  end

  def log_look(player_id)
    @mutex.synchronize do
      File.open(@path, 'a') do |log_file|
        timestamp = Time.now.strftime("[%Y-%m-%d %H:%M:%S]")
        log_file.puts "#{timestamp} player '#{player_id}' made a look request."
      end
    end
  end

  def log_flip(player_id, row, column)
    @mutex.synchronize do
      File.open(@path, 'a') do |log_file|
        timestamp = Time.now.strftime("[%Y-%m-%d %H:%M:%S]")
        log_file.puts "#{timestamp} player '#{player_id}' made a flip request to row #{row}, column #{column}."
      end
    end
  end

  def log_map(player_id, from_card, to_card)
    @mutex.synchronize do
      File.open(@path, 'a') do |log_file|
        timestamp = Time.now.strftime("[%Y-%m-%d %H:%M:%S]")
        log_file.puts "#{timestamp} player '#{player_id}' made a map request from #{from_card} to #{to_card}."
      end
    end
  end

  def log_watch(player_id)
    @mutex.synchronize do
      File.open(@path, 'a') do |log_file|
        timestamp = Time.now.strftime("[%Y-%m-%d %H:%M:%S]")
        log_file.puts "#{timestamp} player '#{player_id}' made a watch request."
      end
    end
  end
end