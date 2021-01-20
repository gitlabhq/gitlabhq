# frozen_string_literal: true

require_relative 'base_linter'

module Tooling
  module Danger
    class MergeRequestLinter < BaseLinter
      alias_method :lint, :lint_subject

      def self.subject_description
        'merge request title'
      end

      def self.mr_run_options_regex
        [
          'RUN AS-IF-FOSS',
          'UPDATE CACHE',
          'RUN ALL RSPEC',
          'SKIP RSPEC FAIL-FAST'
        ].join('|')
      end

      private

      def subject
        super.gsub(/\[?(#{self.class.mr_run_options_regex})\]?/, '').strip
      end
    end
  end
end
