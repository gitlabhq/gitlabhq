# frozen_string_literal: true

require_relative '../suggestion'

module Tooling
  module Danger
    module Specs
      class MatchWithArraySuggestion < Suggestion
        MATCH = /(?<to>to\(?\s*)(?<matcher>match|eq)(?<expectation>[( ]?\[(?=.*,)[^\]]+)/
        REPLACEMENT = '\k<to>match_array\k<expectation>'
        SUGGESTION = <<~SUGGEST_COMMENT
          If order of the result is not important, please consider using `match_array` to avoid flakiness.
        SUGGEST_COMMENT
      end
    end
  end
end
