require "spec_helper"

describe ActsAsStream::StreamableObject do

  before :each do
    @user = Factory :user
    @admin = Factory :admin
    @widget = Factory :widget
    @thing = Factory :thing
    @user_base = "redis_stream_test:activity"
    @admin_base = "redis_stream_test:actions"
  end

  it "should load correctly into a model" do
    @user.class.activity_scope.should eq(ActsAsStream.activity_scope)
    @thing.class.activity_scope.should eq(ActsAsStream.activity_scope)
    @admin.class.activity_scope.should eq(:actions)
    @admin.class.activity_attr.should eq(:guid)
    @widget.class.activity_scope.should eq(:people_doings)
  end

  it "should provide a proper activity_key_base" do
    @user.class.activity_key_base.should eq(@user_base)
    @admin.class.activity_key_base.should eq(@admin_base)
  end
  it "should provide a proper activity key" do
    @user.activity_key.should eq("#{@user_base}:by:user:#{@user.id}")
    @admin.activity_key.should eq("#{@admin_base}:by:admin:#{@admin.guid}")
  end
  it "should return a paged list of activity packages" do
    usera = Factory :user
    packages = (1..26).collect{|i| test_package i}
    usera.follow! @user
    packages.each{|p| @user.register_activity! p}
    usera.get_activity_for.should =~ packages[1..25]
    usera.get_activity_for(:page_size => 10).size.should be(10)
    usera.get_activity_for(:all => true).should =~ packages
  end

  describe "Followers" do
    it "should provide a proper following key" do
      @user.following_key.should eq("redis_stream_test:activity:for:user:#{@user.id}")
      @admin.following_key.should eq("redis_stream_test:actions:for:admin:#{@admin.guid}")
    end
    it "Should register following activity in followers" do
      usera = Factory :user
      userb = Factory :user
      package = test_package
      usera.follow! @user
      @user.register_activity! package
      ActsAsStream.redis.zcard(usera.following_key).should be(1)
      ActsAsStream.redis.zcard(userb.following_key).should be(0)
    end
    it "should return a list of all followers as a keyed list" do
      users = (1..3).collect{Factory :user}
      users.each{|u| u.follow! @user}
      @user.get_follower_keys.should =~ users.map{|u| u.following_key}
    end

  end

  describe "Mentions" do
    it "should provide a proper mentions key" do
      @user.mentioned_by_others_key.should eq("redis_stream_test:mentions:of:user:#{@user.id}")
      @admin.mentioned_by_others_key.should eq("redis_stream_test:notifications:of:admin:#{@admin.guid}")
    end
    it "Should register mentions activity" do
      usera = Factory :user
      userb = Factory :user
      lst = [usera, @admin, @thing]
      package = test_package
      id = @user.register_activity! package
      @user.register_mentions! :activity_id => id, :mentioned_keys => lst.map{|u| u.mentioned_by_others_key}
      ActsAsStream.redis.zcard(usera.mentioned_by_others_key).should be(1)
      ActsAsStream.redis.zcard(@admin.mentioned_by_others_key).should be(1)
      ActsAsStream.redis.zcard(@thing.mentioned_by_others_key).should be(1)
      ActsAsStream.redis.zcard(userb.mentioned_by_others_key).should be(0)

      ActsAsStream.redis.zcard(@user.mentions_key).should be(1)
    end
    it "should return a list of all followers as a keyed list" do
      users = (1..3).collect{Factory :user}
      users.each{|u| u.follow! @user}
      @user.get_follower_keys.should =~ users.map{|u| u.following_key}
    end

    it "should return a paged list of mentions packages" do
      usera = Factory :user
      packages = (1..26).collect{|i| test_package i}
      usera.follow! @user
      packages.each do |p|
        id = @user.register_activity! p
        @user.register_mentions! :activity_id => id, :mentioned_keys => usera.mentioned_by_others_key
      end
      usera.get_mentions_activity.should =~ packages[1..25]
      usera.get_mentions_activity(:page_size => 10).size.should be(10)
      usera.mentions_count.should be(26)
      usera.get_mentions_activity(:all=>true).should =~ packages
    end

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
