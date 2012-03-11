class RestObject < ActiveResource::Base

  acts_as_stream
  self.site = "http://api.sample.com"

  self.format = :xml

end
