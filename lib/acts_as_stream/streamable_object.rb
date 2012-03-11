module ActsAsStream
  module StreamableObject

    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods

      def acts_as_stream options = {}
        cattr_accessor :activity_scope, :activity_attr, :activity_key_base
        self.activity_scope = options[:activity_scope] || ActsAsStream.activity_scope
        self.activity_attr = options[:activity_attr] || ActsAsStream.activity_attr
        self.activity_key_base = "#{ActsAsStream.namespace}:#{self.name.downcase}:#{self.activity_scope}"
        send :include, ActsAsStream::StreamableObject::InstanceMethods
      end
    end

    module InstanceMethods

      def activity_id
        self.send(self.class.activity_attr)
      end
      def activity_key
        "#{self.class.activity_key_base}:#{activity_id}"
      end
      def following_key
        "#{ActsAsStream.namespace}:#{self.class.name.downcase}:#{activity_id}:#{activity_scope}"
      end


    end
  end
end