# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project.value_streams', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:query) do
    <<~QUERY
      query($fullPath: ID!) {
        project(fullPath: $fullPath) {
          valueStreams {
            nodes {
              name
              stages {
                name
                startEventIdentifier
                endEventIdentifier
              }
            }
          }
        }
      }
    QUERY
  end

  context 'when user has permissions to read value streams' do
    let(:expected_value_stream) do
      {
        'project' => {
          'valueStreams' => {
            'nodes' => [
              {
                'name' => 'default',
                'stages' => expected_stages
              }
            ]
          }
        }
      }
    end

    let(:expected_stages) do
      [
        {
          'name' => 'issue',
          'startEventIdentifier' => 'ISSUE_CREATED',
          'endEventIdentifier' => 'ISSUE_STAGE_END'
        },
        {
          'name' => 'plan',
          'startEventIdentifier' => 'PLAN_STAGE_START',
          'endEventIdentifier' => 'ISSUE_FIRST_MENTIONED_IN_COMMIT'
        },
        {
          'name' => 'code',
          'startEventIdentifier' => 'CODE_STAGE_START',
          'endEventIdentifier' => 'MERGE_REQUEST_CREATED'
        },
        {
          'name' => 'test',
          'startEventIdentifier' => 'MERGE_REQUEST_LAST_BUILD_STARTED',
          'endEventIdentifier' => 'MERGE_REQUEST_LAST_BUILD_FINISHED'
        },
        {
          'name' => 'review',
          'startEventIdentifier' => 'MERGE_REQUEST_CREATED',
          'endEventIdentifier' => 'MERGE_REQUEST_MERGED'
        },
        {
          'name' => 'staging',
          'startEventIdentifier' => 'MERGE_REQUEST_MERGED',
          'endEventIdentifier' => 'MERGE_REQUEST_FIRST_DEPLOYED_TO_PRODUCTION'
        }
      ]
    end

    before_all do
      project.add_guest(user)
    end

    before do
      post_graphql(query, current_user: user, variables: { fullPath: project.full_path })
    end

    it_behaves_like 'a working graphql query'

    it 'returns only `default` value stream' do
      expect(graphql_data).to eq(expected_value_stream)
    end
  end

  context 'when user does not have permission to read value streams' do
    before do
      post_graphql(query, current_user: user, variables: { fullPath: project.full_path })
    end

    it 'returns nil' do
      expect(graphql_data_at(:project, :valueStreams)).to be_nil
    end
  end
end
