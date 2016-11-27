require 'hashie'

module SimpleFeed
  class Response

    def initialize(data = {})
      @result = data.dup
    end

    def for(key_or_user_id, result = nil)
      user_id = key_or_user_id.is_a?(SimpleFeed::Providers::Key) ?
        key_or_user_id.user_id :
        key_or_user_id

      @result[user_id] = result ? result : yield
    end

    def user_ids
      @result.keys
    end

    # Passes results assigned to each user to a transformation
    # function that in turn must return a transformed value for
    # an individual response, and be implemented in the subclasses
    def transform
      if block_given?
        @result.each_pair do |user_id, value|
          @result[user_id] = yield(user_id, value)
        end
      end
    end

    def result(user_id = nil)
      if user_id then
        @result[user_id]
      else
        if @result.values.size == 1
          @result.values.first
        else
          @result.to_hash
        end
      end
    end

    alias_method :[], :result
  end
end
