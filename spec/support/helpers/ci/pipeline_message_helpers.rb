# frozen_string_literal: true

module Ci
  module PipelineMessageHelpers
    def sanitize_message(message)
      ActionController::Base.helpers.sanitize(message, tags: [])
    end
  end
end
