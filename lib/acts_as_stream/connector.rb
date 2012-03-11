module ActsAsStream
  module Connector

    def register_new_activity! options = {}
      options.assert_valid_keys(:key, :score, :package)

    end

    private

    def time
      Time.now.to_i
    end
  end
end