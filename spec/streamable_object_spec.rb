require "spec_helper"

describe ActsAsStream::StreamableObject do

  before :each do
    @user = Factory :user
    @admin = Factory :admin
    @widget = Factory :widget
    @thing = Factory :thing
    @user_base = "redis_stream_test:user:activity"
    @admin_base = "redis_stream_test:admin:actions"
  end

  describe "loading" do
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
      @user.activity_key.should eq("#{@user_base}:#{@user.id}")
      @admin.activity_key.should eq("#{@admin_base}:#{@admin.guid}")
    end

    it "should provide a proper following key" do
      @user.following_key.should eq("redis_stream_test:user:#{@user.id}:activity")
      @admin.following_key.should eq("redis_stream_test:admin:#{@admin.guid}:actions")
    end

  end
end
