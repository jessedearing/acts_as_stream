class Widget < ActiveRecord::Base
  acts_as_stream :activity_scope => :people_doings, :ignore_mentions => true
  acts_as_amico

  def all_followers
    get_all(:followers).map{|id| User.find(id.to_i)}.map{|u| u.following_key}
  end

end
