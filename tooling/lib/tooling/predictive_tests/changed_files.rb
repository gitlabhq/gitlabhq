# frozen_string_literal: true

require_relative '../find_files_using_feature_flags'
require_relative '../mappings/partial_to_views_mappings'
require_relative '../mappings/view_to_js_mappings'

module Tooling
  module PredictiveTests
    class ChangedFiles
      # @return [Regexp] regex for js related file filtering
      JS_FILE_FILTER_REGEX = /\.(js|json|vue|ts|tsx)$/

      class << self
        def fetch(changes:, with_ff_related_files: true, with_views: true, with_js_files: true)
          ff_related_files = with_ff_related_files ? feature_related_files(changes) : []
          view_files = with_views ? view_files(changes) : []
          js_files = with_js_files ? related_js_files(changes + view_files) : []

          (changes + ff_related_files + view_files + js_files).uniq
        end

        private

        def feature_related_files(changes)
          Tooling::FindFilesUsingFeatureFlags.new(changed_files: changes).execute
        end

        def view_files(changes)
          Tooling::Mappings::PartialToViewsMappings.new(changes).execute
        end

        def related_js_files(changes)
          Tooling::Mappings::ViewToJsMappings.new(changes).execute
        end
      end
    end
  end
end
