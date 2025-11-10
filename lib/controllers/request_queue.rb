require 'thread'

class RequestQueue
  def initialize
    @queue = Queue.new
    @waiting_queue = Queue.new
    @watching_queue = Queue.new
    @worker_thread = Thread.new { process_requests }
  end

  def enqueue_look(&block)
    result = Queue.new
    @queue << [block, result, 'look']
    result.pop
  end

  def enqueue_flip(&block)
    result = Queue.new
    @queue << [block, result, 'flip']
    result.pop
  end

  def watch(&block)
    result = Queue.new
    @watching_queue << [block, result, 'watch']
    result.pop
  end

  private

  def process_requests
    loop do
      block, result, request_type = next_request
      begin
        output = block.call
        result << output
        # if successful flip
        update_all_watchers if request_type == 'flip'
        pop_one_waiting_request if request_type == 'flip'
      rescue WaitForCard => e
        # if waiting for card
        update_all_watchers
        @waiting_queue << [block, result, request_type]
      rescue => e
        update_all_watchers
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

  def update_all_watchers
    return if @watching_queue.empty?
    until @watching_queue.empty?
      @queue << @watching_queue.pop(true) rescue ThreadError
    end
  end
end