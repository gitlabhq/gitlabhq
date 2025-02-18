# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).ciVariables', feature_category: :ci_variables do
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
              hidden
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
      variable = create(
        :ci_variable,
        project: project,
        key: 'TEST_VAR',
        value: 'test',
        masked: false,
        protected: true,
        raw: true,
        environment_scope: 'production'
      )

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('project', 'ciVariables', 'limit')).to be(8000)
      expect(graphql_data.dig('project', 'ciVariables', 'nodes')).to contain_exactly({
        'id' => variable.to_global_id.to_s,
        'key' => 'TEST_VAR',
        'value' => 'test',
        'variableType' => 'ENV_VAR',
        'masked' => false,
        'protected' => true,
        'hidden' => false,
        'raw' => true,
        'environmentScope' => 'production'
      })
    end

    it "sets the value to null if the variable is hidden" do
      variable = create(
        :ci_variable,
        project: project,
        key: 'TEST_VAR',
        value: 'TestVariable',
        masked: true,
        hidden: true,
        protected: true,
        raw: false,
        environment_scope: 'production'
      )

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('project', 'ciVariables', 'limit')).to be(8000)
      expect(graphql_data.dig('project', 'ciVariables', 'nodes')).to contain_exactly({
        'id' => variable.to_global_id.to_s,
        'key' => 'TEST_VAR',
        'value' => nil,
        'variableType' => 'ENV_VAR',
        'masked' => true,
        'protected' => true,
        'hidden' => true,
        'raw' => false,
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

  describe 'sorting and pagination' do
    let_it_be(:current_user) { user }
    let_it_be(:data_path) { [:project, :ci_variables] }
    let_it_be(:variables) do
      [
        create(:ci_variable, project: project, key: 'd'),
        create(:ci_variable, project: project, key: 'a'),
        create(:ci_variable, project: project, key: 'c'),
        create(:ci_variable, project: project, key: 'e'),
        create(:ci_variable, project: project, key: 'b')
      ]
    end

    def pagination_query(params)
      graphql_query_for(
        :project,
        { fullPath: project.full_path },
        query_graphql_field('ciVariables', params, "#{page_info} nodes { id }")
      )
    end

    before do
      project.add_maintainer(current_user)
    end

    it_behaves_like 'sorted paginated variables'
  end
end
