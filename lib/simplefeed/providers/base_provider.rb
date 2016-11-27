require_relative 'key'
module SimpleFeed
  module Providers

    class ProviderMethodNotImplementedError < StandardError
      def initialize(method)
        super("Method #{method} from #{self.class} went to BaseProvider, because no single-user version was defined (#{method}_1u), nor a sub-class override.")
      end
    end

    class BaseProvider
      attr_accessor :feed

      public

      # TODO: single user delegator
      #
      # SimpleFeed::Providers.define_provider_methods(self) do |base, method, *args, **opts|
      #   user_ids = opts.delete(:user_ids)
      #   base.single_user_delegator(method, user_ids, **opts)
      # end
      #
      # def single_user_delegator(method, user_ids, **opts)
      #   single_user_method = "#{method}_1u".to_sym
      #   if self.respond_to?(single_user_method)
      #     with_response_batched(method, user_ids) do |key, response|
      #       response.for(key.user_id) do
      #         self.send(single_user_method, key.user_id, **opts)
      #       end
      #     end
      #   else
      #     raise ProviderMethodNotImplementedError, method
      #   end
      # end

      protected

      def key(user_id)
        ::SimpleFeed::Providers::Key.new(user_id, feed.namespace)
      end

      def time_to_score(at)
        (1000 * at.to_f).to_i
      end

      def to_array(user_ids)
        user_ids.is_a?(Array) ? user_ids : [user_ids]
      end

      def batch_size
        feed.meta[:batch_size] || 100
      end

      def with_response_batched(user_ids, response = nil)
        with_response(response) do |_response|
          batch(user_ids) do |key|
            yield(key, _response)
          end
        end
      end

      def batch(user_ids)
        to_array(user_ids).each_slice(batch_size) do |batch|
          batch.each do |user_id|
            yield(key(user_id))
          end
        end
      end

      def with_response(response = nil)
        response ||= SimpleFeed::Response.new
        yield(response)
        if self.respond_to?(:transform_response)
          response.transform do |user_id, result|
            # calling into a subclass
            transform_response(user_id, result)
          end
        end
        response
      end
    end
  end
end
