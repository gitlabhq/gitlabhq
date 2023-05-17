# frozen_string_literal: true

require_relative '../../../../lib/gitlab_edition'
require_relative '../helpers/file_handler'

# Returns system specs files that are related to the JS files that were changed in the MR.
module Tooling
  module Helpers
    module PredictiveTestsHelper
      include FileHandler

      # Input: A folder
      # Output: An array of folders, each prefixed with a GitLab edition
      def folders_for_available_editions(base_folder)
        foss_prefix        = base_folder
        extension_prefixes = ::GitlabEdition.extensions.map { |prefix| "#{prefix}/#{foss_prefix}" }
        [foss_prefix, *extension_prefixes]
      end
    end
  end
end
