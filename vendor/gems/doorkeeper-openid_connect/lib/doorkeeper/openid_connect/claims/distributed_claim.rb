# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    module Claims
      class DistributedClaim < Claim
        attr_accessor :endpoint, :access_token
      end
    end
  end
end
