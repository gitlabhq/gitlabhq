# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    module Claims
      class NormalClaim < Claim
        attr_reader :generator

        def initialize(options = {})
          super(options)
          @generator = options[:generator]
        end

        def type
          :normal
        end
      end
    end
  end
end
