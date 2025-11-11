require 'thread'

class RequestQueue
  #
  # request queue class
  # - has a global queue that processes active requests
  # - has a waiting queue that schedules waiting requests
  # - has a watching queue that schedules updates for watching players
  # - has a worker thread that processes active requests
  #

  #
  # rep invariant:
  # - @queue [Queue] != nil
  # - @waiting_queue [Queue] != nil
  # - @watching_queue [Queue] != nil
  # - @worker_thread [Thread] is alive
  #

  #
  # creates a new queue
  #
  def initialize
    @queue = Queue.new
    @waiting_queue = Queue.new
    @watching_queue = Queue.new
    @worker_thread = Thread.new { process_requests }
  end

  #
  # checks the rep invariant before every request
  # @raise [StandardError] if any condition is unsatisfied
  #
  def check_rep
    raise "main queue missing" unless @queue.is_a?(Queue)
    raise "waiting queue missing" unless @waiting_queue.is_a?(Queue)
    raise "watching queue missing" unless @watching_queue.is_a?(Queue)
    raise "worker thread missing" unless @worker_thread.is_a?(Thread)
    raise "worker thread is dead" unless @worker_thread.alive?
  end

  #
  # adds look request to the main queue
  # @param block [Proc] code block to be added to queue
  #
  def enqueue_look(&block)
    result = Queue.new
    @queue << [block, result, 'look']
    result.pop
  end

  #
  # adds flip request to the main queue
  # @param block [Proc] code block to be added to queue
  #
  def enqueue_flip(&block)
    result = Queue.new
    @queue << [block, result, 'flip']
    result.pop
  end

  #
  # adds map request to the main queue
  # @param block [Proc] code block to be added to queue
  #
  def enqueue_map(&block)
    result = Queue.new
    @queue << [block, result, 'map']
    result.pop
  end

  #
  # adds watch request to the main queue
  # @param block [Proc] code block to be added to queue
  #
  def enqueue_watch(&block)
    result = Queue.new
    @watching_queue << [block, result, 'watch']
    result.pop
  end

  private

  #
  # continuously processes queue items
  #
  def process_requests
    loop do
      check_rep
      block, result, request_type = next_request
      begin
        output = block.call
        result << output
        # if successful flip
        update_all_watchers if request_type == 'flip' or request_type == 'map'
        pop_one_waiting_request if request_type == 'flip'
      rescue WaitForCard => e
        # if waiting for card
        @waiting_queue << [block, result, request_type]
      rescue => e
        update_all_watchers
        result << e
      end
    end
  end

  # helper to pop the queue
  def next_request
    @queue.pop
  end

  # helper to advance waiting requests
  def pop_one_waiting_request
    return if @waiting_queue.empty?
    @queue << @waiting_queue.pop(true) rescue ThreadError
  end

  # helper to advance watching requests
  def update_all_watchers
    until @watching_queue.empty?
      @queue << @watching_queue.pop(true)
    end
  end
end