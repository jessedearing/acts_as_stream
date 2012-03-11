require 'acts_as_amico'

Amico.configure do |configuration|
  configuration.redis = Redis.new
  configuration.namespace = 'acts_as_amico'
  configuration.following_key = 'following'
  configuration.followers_key = 'followers'
  configuration.blocked_key = 'blocked'
  configuration.reciprocated_key = 'reciprocated'
  configuration.pending_key = 'pending'
  configuration.default_scope_key = 'user'
  configuration.pending_follow = false
  configuration.page_size = 25
end
