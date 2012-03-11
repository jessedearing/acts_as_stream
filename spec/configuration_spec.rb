require 'spec_helper'

describe ActsAsStream::Configuration do
  describe '#configure' do
    it 'should have default attributes' do
      ActsAsStream.configure do |configuration|
        configuration.namespace.should eql(:redis_stream_test)
        configuration.activity_scope.should eql(:activity)
        configuration.activity_key.should eql(:activity)
        configuration.activity_attr.should be(:id)
        configuration.page_size.should be(25)
        configuration.activity_attr.should be(:id)
        configuration.activity_incr.should be(:activity_counter)
      end
    end
  end
end