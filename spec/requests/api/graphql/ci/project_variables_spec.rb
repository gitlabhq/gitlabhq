# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).ciVariables', feature_category: :pipeline_authoring do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          ciVariables {
            limit
            nodes {
              id
              key
              value
              variableType
              protected
              masked
              raw
              environmentScope
            }
          }
        }
      }
    )
  end

  context 'when the user can administer builds' do
    before do
      project.add_maintainer(user)
    end

    it "returns the project's CI variables" do
      variable = create(:ci_variable, project: project, key: 'TEST_VAR', value: 'test',
                                      masked: false, protected: true, raw: true, environment_scope: 'production')

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('project', 'ciVariables', 'limit')).to be(200)
      expect(graphql_data.dig('project', 'ciVariables', 'nodes')).to contain_exactly({
        'id' => variable.to_global_id.to_s,
        'key' => 'TEST_VAR',
        'value' => 'test',
        'variableType' => 'ENV_VAR',
        'masked' => false,
        'protected' => true,
        'raw' => true,
        'environmentScope' => 'production'
      })
    end
  end

  context 'when the user cannot administer builds' do
    it 'returns nothing' do
      create(:ci_variable, project: project, value: 'verysecret', masked: true)

      project.add_developer(user)

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('project', 'ciVariables')).to be_nil
    end
  end
end
