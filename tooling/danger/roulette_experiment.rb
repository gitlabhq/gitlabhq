# frozen_string_literal: true

require 'digest'

module Tooling
  module Danger
    module RouletteExperiment
      SALT = 'reviewer-column-2026-08'
      PERCENT_ENV_VAR = 'ROULETTE_HIDE_REVIEWER_COLUMN_PERCENT'
      DEFAULT_HIDDEN_PERCENT = 50

      def self.hide_reviewer_column?(mr_iid)
        Digest::SHA256.hexdigest("#{SALT}-#{mr_iid}").to_i(16) % 100 < hidden_percent
      end

      # Read on every call rather than memoized, so a CI variable change takes
      # effect on the next pipeline without a code change.
      def self.hidden_percent
        Integer(ENV.fetch(PERCENT_ENV_VAR, DEFAULT_HIDDEN_PERCENT))
      end
    end
  end
end
