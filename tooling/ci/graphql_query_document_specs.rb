#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/tooling/mappings/graphql_query_document_mappings'

module CI
  # Picks the integration specs that read a changed GraphQL query file.
  class GraphqlQueryDocumentSpecs
    GRAPHQL_FILE_FILTER = %r{\A(?:ee/|jh/)?app/assets/javascripts/.*\.graphql\z}

    def initialize(scope: nil)
      @scope = scope
    end

    attr_reader :scope

    def changed_graphql_files
      changed_files_with_old_paths.grep(GRAPHQL_FILE_FILTER)
    end

    # Include renamed and deleted paths so specs still quoting them run.
    def changed_files_with_old_paths
      files = `git diff --name-only --no-renames HEAD~..HEAD`
      raise "git diff failed" unless $?.success?

      files.split("\n")
    end

    def matching_specs
      specs = Tooling::Mappings::GraphqlQueryDocumentMappings.new(changed_graphql_files).execute

      case scope
      when 'ee'
        specs.select { |spec_file| spec_file.start_with?('ee/') }
      when 'foss'
        specs.reject { |spec_file| spec_file.start_with?('ee/') }
      else
        specs
      end
    end
  end
end

puts CI::GraphqlQueryDocumentSpecs.new(scope: ARGV[0]).matching_specs.join(' ') if __FILE__ == $PROGRAM_NAME
