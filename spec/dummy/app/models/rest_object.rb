class RestObject < ActiveResource::Base

  acts_as_stream :activity_scope => :rest_activity
  acts_as_amico
  self.site = "http://api.sample.com"

  self.format = :xml

  def all_followers
    get_all(:followers).map{|id| User.find(id.to_i)}.map{|u| u.following_key}
  end

end
