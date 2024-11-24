# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    module Claims
      class AggregatedClaim < Claim
        attr_accessor :jwt
      end
    end
  end
end
