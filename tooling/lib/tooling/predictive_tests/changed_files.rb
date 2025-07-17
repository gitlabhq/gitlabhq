# frozen_string_literal: true

require_relative '../find_files_using_feature_flags'
require_relative '../mappings/partial_to_views_mappings'

module Tooling
  module PredictiveTests
    class ChangedFiles
      class << self
        def fetch(changes:, with_ff_related_files: true, with_views: true)
          ff_related_files = with_ff_related_files ? feature_related_files(changes) : []
          view_files = with_views ? view_files(changes) : []

          (changes + ff_related_files + view_files).uniq
        end

        private

        def feature_related_files(changes)
          Tooling::FindFilesUsingFeatureFlags.new(changed_files: changes).execute
        end

        def view_files(changes)
          Tooling::Mappings::PartialToViewsMappings.new(changes).execute
        end
      end
    end
  end
end
