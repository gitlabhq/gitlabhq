# frozen_string_literal: true

module Tooling
  module Danger
    module SpecOnly
      SPEC_ONLY_LABEL = 'pipeline:spec-only'
      SPEC_FILE_REGEX = %r{_spec\.rb\z}

      def add_or_remove_label
        if only_spec_files? && !has_label?
          helper.labels_to_add << SPEC_ONLY_LABEL
        elsif !only_spec_files? && has_label?
          remove_label
        end
      end

      private

      def only_spec_files?
        changed_files = helper.all_changed_files
        changed_files.any? && changed_files.all? { |file| file.match?(SPEC_FILE_REGEX) }
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
