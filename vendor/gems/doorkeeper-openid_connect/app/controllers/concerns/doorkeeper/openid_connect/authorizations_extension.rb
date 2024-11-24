module Doorkeeper
  module OpenidConnect
    module AuthorizationsExtension
      private

      def pre_auth_param_fields
        super.append(:nonce)
      end
    end
  end
end

