module ActsAsStream
  # Configuration settings for ActsAsStream.
  module Configuration
    # Redis instance.
    attr_accessor :redis

    attr_writer :namespace,
                :activity_key,
                :activity_scope,
                :activity_attr,
                :page_size,
                :activity_incr

    def configure
      yield self
      if activity_incr.nil?
        warn "You should really define :activity_incr in ActsAsStream Configuration. Using '#{ActsAsStream.namespace}:activity_counter', but that's pretty unsafe!"
        @activity_incr = "#{ActsAsStream.namespace}:activity_counter"
        ActsAsStream.redis.set @activity_incr, 0
      end
      ActsAsStream.redis.setnx(@activity_incr, 0)
    end

    def namespace
      @namespace ||= :activity_stream
    end

    def activity_key
      @activity_key ||= :activity
    end

    def activity_scope
      @activity_scope ||= :activity
    end

    def activity_attr
      @activity_attr ||= :id
    end

    def page_size
      @page_size ||= 25
    end

    def activity_incr
      @activity_incr
    end

  end
end