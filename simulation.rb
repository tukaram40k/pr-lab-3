require 'net/http'
require 'uri'
require 'securerandom'

def player(id)
  total_time = 0.0
  num_requests = 100

  num_requests.times do
    x = rand(0..39)
    y = rand(0..39)
    url = URI("http://localhost:4567/flip/#{id}/#{x},#{y}")

    start_time = Time.now
    begin
      Net::HTTP.get_response(url)
    rescue => e
      puts "player #{id} request failed: #{e.message}"
    end
    end_time = Time.now

    total_time += (end_time - start_time)

    sleep(rand * 0.002)
  end

  avg_time = total_time / num_requests
  RESULTS << "player #{id} average response time: #{(avg_time * 1000).round(3)} ms"
end

threads = []
RESULTS = []

10.times do
  player_id = SecureRandom.hex(4)
  threads << Thread.new { player(player_id) }
end

threads.each(&:join)

RESULTS.each do |result|
  puts result
end
