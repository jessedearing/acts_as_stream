require 'spec_helper'

describe ActsAsStream::Connector do

  before :each do
    @users = Factory :user
    @admins = Factory :admin
    @widget = Factory :widget
    @thing = Factory :thing
    @key = ActsAsStream.base_key
    @package = test_package
  end

  it "should get the counter incrementor" do
    counter = ActsAsStream.count
    counter.should be(0)
  end

  it "should register a new activity" do
    ActsAsStream.register_new_activity! :key => @key, :package => @package
    key = "#{@key}:#{ActsAsStream.count-1}"
    ActsAsStream.redis.get(key).should == @package
  end

  it "should register time keys with new activity" do
    id = ActsAsStream.count
    # we're assuming this test will take less than one second!
    time = Time.now.to_i
    items = ActsAsStream.redis.zcard("#{@key}:time:#{time}")
    ActsAsStream.register_new_activity! :key => @key, :package => @package

    ActsAsStream.redis.get("#{@key}:#{id}").should == @package
    score = ActsAsStream.redis.get("#{@key}:id:#{id}")
    score.to_i.should == time
    (ActsAsStream.redis.zcard("#{@key}:time:#{score}") - items).should be(1)
    ActsAsStream.redis.zrevrange("#{@key}:time:#{score}",0,25,:with_scores => false).include?("#{id}").should be_true
  end

  it "should remove all keys on deregistration" do
    id = ActsAsStream.count
    # we're assuming this test will take less than one second!
    time = Time.now.to_i
    items = ActsAsStream.redis.zcard("#{@key}:time:#{time}")
    ActsAsStream.register_new_activity! :key => @key, :package => @package

    ActsAsStream.redis.get("#{@key}:#{id}").should == @package
    score = ActsAsStream.redis.get("#{@key}:id:#{id}")
    score.to_i.should == time
    (ActsAsStream.redis.zcard("#{@key}:time:#{score}") - items).should be(1)
    ActsAsStream.redis.zrevrange("#{@key}:time:#{score}",0,25,:with_scores => false).include?("#{id}").should be_true

    ActsAsStream.deregister_activity! :key => @key, :id => id

    ActsAsStream.redis.get("#{@key}:#{id}").should be(nil)
    ActsAsStream.redis.get("#{@key}:id:#{id}").should be(nil)
    ActsAsStream.redis.zcard("#{@key}:time:#{score}").should == items
    ActsAsStream.redis.zrevrange("#{@key}:time:#{score}",0,25,:with_scores => false).include?("#{id}").should be_false
  end

  it "should add a weighted record to the sorted set for a list of followers" do
    id = ActsAsStream.count
    ActsAsStream.register_new_activity! :key => @key, :package => "########################################"
    followers = [23,32,42].map{|f| "#{@key}:user:#{f}"}
    ActsAsStream.register_followers! :following_keys => followers, :activity_id => id

    followers.each do |f|
      ActsAsStream.redis.zcard(f).should be(1)
      ActsAsStream.redis.zrevrange(f,0,25,:with_scores=>false).should =~ ["#{id}"]
      ActsAsStream.redis.lrange("#{@key}:followers:#{id}",0,15).include?(f).should be_true
    end
    ActsAsStream.redis.llen("#{@key}:followers:#{id}").should be(3)
  end

  it "should remove followers on deregistration" do
    id = ActsAsStream.count
    ActsAsStream.register_new_activity! :key => @key, :package => "########################################"
    followers = [56,43,65].map{|f| "#{@key}:user:#{f}"}
    ActsAsStream.register_followers! :following_keys => followers, :activity_id => id

    followers.each do |f|
      ActsAsStream.redis.zcard(f).should be(1)
      ActsAsStream.redis.zrevrange(f,0,25,:with_scores=>false).should =~ ["#{id}"]
      ActsAsStream.redis.lrange("#{@key}:followers:#{id}",0,15).include?(f).should be_true
    end
    ActsAsStream.redis.llen("#{@key}:followers:#{id}").should be(3)

    ActsAsStream.deregister_activity! :key => @key, :id => id

    followers.each do |f|
      ActsAsStream.redis.zcard(f).should be(0)
      ActsAsStream.redis.lrange("#{@key}:followers:#{id}",0,15).include?(f).should be_false
    end
    ActsAsStream.redis.llen("#{@key}:followers:#{id}").should be(0)

  end

  it "should automatically score" do
    time = Time.now.to_i
    sleep 1
    ActsAsStream.register_new_activity! :key => @key, :package => @package
    key = "#{@key}:#{ActsAsStream.count-1}"
    ActsAsStream.redis.get(key).should == @package
  end

  it "should deregister an activity" do
    ActsAsStream.register_new_activity! :key => @key, :package => @package
    key = "#{@key}:#{ActsAsStream.count-1}"
    ActsAsStream.redis.get(key).should == @package

    ActsAsStream.deregister_activity! :key => @key, :id => ActsAsStream.count-1
    ActsAsStream.redis.get(key).should be(nil)
  end

  private

  def test_package
    "{'test':#{Time.now}}"
  end
end