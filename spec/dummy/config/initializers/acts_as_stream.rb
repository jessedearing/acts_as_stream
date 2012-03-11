ActsAsStream.configure do |configuration|
  redis = Redis.new(:db => 15)
  configuration.redis = redis
  configuration.namespace = :redis_stream_test
  configuration.activity_incr = :activity_counter
end
