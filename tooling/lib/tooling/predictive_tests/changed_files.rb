# frozen_string_literal: true

require_relative '../find_changes'
require_relative '../find_files_using_feature_flags'
require_relative '../mappings/partial_to_views_mappings'

module Tooling
  module PredictiveTests
    class ChangedFiles
      class << self
        def fetch(with_ff_related_files: true, with_views: true, frontend_fixtures_file: nil)
          changes = []
          changes.push(*mr_changes(frontend_fixtures_file))
          changes.push(*feature_related_files(changes)) if with_ff_related_files
          changes.push(*view_files(changes)) if with_views

          changes.uniq
        end

        private

        def mr_changes(frontend_fixtures_file)
          Tooling::FindChanges.new(from: :api, frontend_fixtures_mapping_pathname: frontend_fixtures_file).execute
        end

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
