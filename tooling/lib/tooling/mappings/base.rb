# frozen_string_literal: true

require_relative '../../../../lib/gitlab_edition'

# Returns system specs files that are related to the JS files that were changed in the MR.
module Tooling
  module Mappings
    class Base
      # Input: A list of space-separated files
      # Output: A list of space-separated specs files (JS, Ruby, ...)
      def execute(changed_files)
        raise "Not Implemented"
      end

      # Input: A list of space-separated files
      # Output: array/hash of files
      def filter_files(changed_files)
        raise "Not Implemented"
      end

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
