module ActsAsStream
  module Connector

    def register_new_activity! options = {}
      options.assert_valid_keys(:key, :package)
      return if options[:key].nil? or options[:package].nil?

      #Add the key and package to the system
      ActsAsStream.redis.set "#{options[:key]}:#{count}", options[:package]
      #Add a timed key, scored by id, and an id-based key
      score = Time.now.to_i
      ActsAsStream.redis.zadd "#{base_key}:time:#{score}", count, count
      ActsAsStream.redis.set "#{base_key}:id:#{count}", score
      increment!
    end

    def deregister_activity! options = {}
      options.assert_valid_keys(:key, :id)
      return if options[:key].nil? or options[:id].nil?
      ActsAsStream.redis.del "#{options[:key]}:#{options[:id]}"
      score = ActsAsStream.redis.get "#{options[:key]}:id:#{options[:id]}"
      ActsAsStream.redis.zrem "#{base_key}:time:#{score}", options[:id]
      ActsAsStream.redis.del "#{base_key}:id:#{options[:id]}"
      deregister_followers! :activity_id => options[:id]
    end

    def register_followers! options = {}
      options.assert_valid_keys(:following_keys, :activity_id)
      return if options[:following_keys].nil? or options[:activity_id].nil?
      raise ":following_keys must be an array of keys" if not options[:following_keys].is_a? Array
      time = Time.now.to_i

      ActsAsStream.redis.multi do
        options[:following_keys].each do |key|
          ActsAsStream.redis.zadd key, time, options[:activity_id]
          ActsAsStream.redis.lpush "#{base_key}:followers:#{options[:activity_id]}", key
        end
      end
    end

    def deregister_followers! options = {}
      options.assert_valid_keys :activity_id
      followers_key = "#{base_key}:followers:#{options[:activity_id]}"
      len = ActsAsStream.redis.llen followers_key
      followers = ActsAsStream.redis.lrange followers_key, 0, len
      return if followers.nil?
      ActsAsStream.redis.multi do
        followers.each do |f|
          ActsAsStream.redis.zrem f, options[:activity_id]
        end
        ActsAsStream.redis.del "#{base_key}:followers:#{options[:activity_id]}"
      end
    end

    def count
      ActsAsStream.redis.get(ActsAsStream.activity_incr).to_i
    end

    def base_key
      "#{ActsAsStream.namespace}:#{ActsAsStream.activity_scope}"
    end
    private

    def increment!
      ActsAsStream.redis.incr(ActsAsStream.activity_incr)
    end
    def time
      Time.now.to_i
    end
  end
end