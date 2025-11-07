require 'thread'

class RequestQueue
  def initialize
    @queue = Queue.new
    @worker_thread = Thread.new { process_requests }
  end

  def enqueue(&block)
    result = Queue.new
    @queue << [block, result]
    result.pop
  end

  private

  def process_requests
    loop do
      block, result = @queue.pop
      begin
        output = block.call
        result << output
      rescue => e
        result << e
      end
    end
  end
end
