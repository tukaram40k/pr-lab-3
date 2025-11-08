require 'thread'

class RequestQueue
  def initialize
    @queue = Queue.new
    @waiting_queue = Queue.new
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
      block, result = next_request
      begin
        output = block.call
        result << output
        # if successful request
        pop_one_waiting_request
      rescue WaitForCard => e
        # if waiting for card
        @waiting_queue << [block, result]
      rescue => e
        result << e
      end
    end
  end

  def next_request
    @queue.pop
  end

  def pop_one_waiting_request
    return if @waiting_queue.empty?
    @queue << @waiting_queue.pop(true) rescue ThreadError
  end
end
