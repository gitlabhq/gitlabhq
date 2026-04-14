# frozen_string_literal: true

require_relative '../../../lib/gitlab/fp/message'

module AiHarness
  module Doctor
    module Messages
      class InvalidArguments < Gitlab::Fp::Message; end
    end
  end
end
