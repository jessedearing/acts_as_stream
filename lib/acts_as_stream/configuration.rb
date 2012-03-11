module ActsAsStream
  # Configuration settings for ActsAsStream.
  module Configuration
    # Redis instance.
    attr_accessor :redis

    attr_writer :namespace, :activity_key, :activity_scope, :activity_attr, :page_size

    def configure
      yield self
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
  end
end