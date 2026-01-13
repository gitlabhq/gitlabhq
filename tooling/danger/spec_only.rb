# frozen_string_literal: true

module Tooling
  module Danger
    module SpecOnly
      SPEC_ONLY_LABEL = 'pipeline:spec-only'
      SPEC_FILE_REGEX = %r{\A(ee/|jh/)?spec/}
      DOC_FILE_REGEX = %r{
        \Adoc/|
        \.(yml|yaml|md)\z|
        \Alocale/.*gitlab\.po\z|
        \Afixtures/emojis/
      }x

      def add_or_remove_label
        if spec_only_eligible? && !has_label?
          helper.labels_to_add << SPEC_ONLY_LABEL
        elsif !spec_only_eligible? && has_label?
          remove_label
        end
      end

      private

      def spec_only_eligible?
        changed_files = helper.all_changed_files
        return false if changed_files.empty?

        has_spec_files = changed_files.any? { |file| file.match?(SPEC_FILE_REGEX) }
        return false unless has_spec_files

        non_spec_files = changed_files.reject { |file| file.match?(SPEC_FILE_REGEX) }
        non_spec_files.all? { |file| file.match?(DOC_FILE_REGEX) }
      end

      def has_label?
        helper.mr_labels.include?(SPEC_ONLY_LABEL)
      end

      def remove_label
        gitlab.api.update_merge_request(
          gitlab.mr_json['project_id'],
          gitlab.mr_json['iid'],
          remove_labels: SPEC_ONLY_LABEL
        )
      end
    end
  end
end
