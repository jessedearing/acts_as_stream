module ActsAsStream
  module StreamableObject

    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods

      def acts_as_stream options = {}
        cattr_accessor :activity_scope, :activity_attr, :activity_key_base, :followers_attr
        self.activity_scope = options[:activity_scope] || ActsAsStream.activity_scope
        self.activity_attr = options[:activity_attr] || ActsAsStream.activity_attr
        self.activity_key_base = "#{ActsAsStream.namespace}:#{self.activity_scope}"
        self.followers_attr = options[:followers_attr] || :all_followers
        send :include, ActsAsStream::StreamableObject::InstanceMethods
      end
    end

    module InstanceMethods

      def to_stream_hash
        {self.class.name.tableize.singularize => {'id' => self.id, activity_attr.to_s => self.send(activity_attr)}}
      end
      def activity_id
        self.send(self.class.activity_attr)
      end
      def activity_key
        "#{self.class.activity_key_base}:#{activity_id}"
      end
      def following_key
        "#{ActsAsStream.namespace}:#{self.class.name.tableize.singularize}:#{activity_id}:#{activity_scope}"
      end

      def register_activity! package
        act_id = ActsAsStream.register_new_activity! package
        self.register_followers! act_id
      end

      def delete_activity act_id
        ActsAsStream.deregister_activity! act_id
      end

      def register_followers! act_id
        ActsAsStream.register_followers! :following_keys => get_follower_keys, :activity_id => act_id
      end

      def get_follower_keys
        send(followers_attr)
      end

      def get_activity options = {}
        if options == :all
          ActsAsStream.get_activity_for following_key,
                                        :page_size => activity_count,
                                        :page => 1
        else
          options = {:page_size => ActsAsStream.page_size, :page => 1}.merge options
          ActsAsStream.get_activity_for following_key, :page_size => options[:page_size], :page => options[:page]
        end
      end

      def activity_count
        ActsAsStream.redis.zcard following_key
      end

    end
  end
end