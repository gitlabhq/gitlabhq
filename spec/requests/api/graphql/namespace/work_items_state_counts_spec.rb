# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Work Item counts by state', feature_category: :portfolio_management do
  it_behaves_like 'resolves work item state counts in a project', :namespace do
    def query(args: params)
      fields = <<~QUERY
        #{all_graphql_fields_for('WorkItemStateCountsType'.classify)}
      QUERY

      graphql_query_for(
        'namespace',
        { 'fullPath' => project.full_path },
        query_graphql_field('workItemStateCounts', args, fields)
      )
    end
  end
end
