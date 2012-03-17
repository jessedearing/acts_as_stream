require 'spec_helper'

describe "ActiveResource Objects" do
  before :all do
    FakeWeb.allow_net_connect = false
    @all_resp = '<rest_objects type="array">
                  <rest_object><id>123</id><title>Blah</title><description>Some stuff</description></rest_object>
                  <rest_object><id>321</id><title>Blah</title><description>Some stuff</description></rest_object>
                </rest_objects>'
    @resp_123 = '<rest_object><id>123</id><title>Blah</title><description>Some stuff</description></rest_object>'
    @resp_321 = '<rest_object><id>321</id><title>Blah</title><description>Some stuff</description></rest_object>'

    FakeWeb.register_uri(:get, "http://api.sample.com/rest_objects/123.xml", :body => @resp_123, :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "http://api.sample.com/rest_objects/321.xml", :body => @resp_321, :status => ["200", "OK"])
  end

  after :all do
    FakeWeb.allow_net_connect=true
  end

  before :each do
    @user = Factory :user
    @obj_321 = RestObject.find(321)
    @obj_123 = RestObject.find(123)
    @admin = Factory :admin
    @user.follow! @obj_123
    @user.follow! @obj_321
    @user.follow! @admin
  end

  it "should load correctly into a model" do
    @obj_321.class.activity_scope.should == :rest_activity
  end

  it "should provide a proper activity_key_base" do
    @obj_123.class.activity_key_base.should == "redis_stream_test:rest_activity"
  end
  it "should provide a proper activity key" do
    @obj_123.activity_key.should eq("redis_stream_test:rest_activity:by:rest_object:#{@obj_123.id}")
  end

  it "should provide a proper following key" do
    @obj_123.following_key.should eq("redis_stream_test:rest_activity:for:rest_object:#{@obj_123.id}")
  end

  it "should return a list of all followers as a keyed list" do
    @obj_123.get_follower_keys.should =~ [@user.following_key]
  end

  it "Should register following activity in followers" do
    @obj_321.register_activity! test_package
    @obj_123.register_activity! test_package
    @admin.register_activity! test_package
    ActsAsStream.redis.zcard(@user.following_key).should be(3)
  end

  private
  def test_package number = nil
    if number
      "{'test':'#{Time.now}','number':'#{number}'}"
    else
      "{'test':#{Time.now}}"
    end
  end

end