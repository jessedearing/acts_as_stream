class User < ActiveRecord::Base
  acts_as_stream
  acts_as_amico

  def all_followers
    get_all(:followers).map{|id| User.find(id.to_i)}.map{|u| u.following_key}
  end

end
