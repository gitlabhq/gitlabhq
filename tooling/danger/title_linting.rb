# frozen_string_literal: true

module Tooling
  module Danger
    module TitleLinting
      DRAFT_REGEX = /\A*#{Regexp.union(/(?i)(\[WIP\]\s*|WIP:\s*|WIP$)/, /(?i)(\[draft\]|\(draft\)|draft:|draft\s\-\s|draft$)/)}+\s*/i.freeze
      CHERRY_PICK_REGEX = /cherry[\s-]*pick/i.freeze
      RUN_ALL_RSPEC_REGEX = /RUN ALL RSPEC/i.freeze
      RUN_AS_IF_FOSS_REGEX = /RUN AS-IF-FOSS/i.freeze

      module_function

      def sanitize_mr_title(title)
        remove_draft_flag(title).gsub(/`/, '\\\`')
      end

      def remove_draft_flag(title)
        title.gsub(DRAFT_REGEX, '')
      end

      def has_draft_flag?(title)
        DRAFT_REGEX.match?(title)
      end

      def has_cherry_pick_flag?(title)
        CHERRY_PICK_REGEX.match?(title)
      end

      def has_run_all_rspec_flag?(title)
        RUN_ALL_RSPEC_REGEX.match?(title)
      end

      def has_run_as_if_foss_flag?(title)
        RUN_AS_IF_FOSS_REGEX.match?(title)
      end
    end
  end
end
