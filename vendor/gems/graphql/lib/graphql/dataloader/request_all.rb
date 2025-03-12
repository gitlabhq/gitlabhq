# frozen_string_literal: true
module GraphQL
  class Dataloader
    # @see Source#request_all which returns an instance of this.
    class RequestAll < Request
      def initialize(source, keys)
        @source = source
        @keys = keys
      end

      # Call this method to cause the current Fiber to wait for the results of this request.
      #
      # @return [Array<Object>] One object for each of `keys`
      def load
        @source.load_all(@keys)
      end
    end
  end
end
