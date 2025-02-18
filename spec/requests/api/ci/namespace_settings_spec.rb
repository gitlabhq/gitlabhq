# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting namespace settings in a namespace', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let(:namespace) { create(:group, :public) }
  let(:namespace_settings) { namespace.namespace_settings }
  let(:current_user) { create(:user) }

  let(:namespace_settings_response) { graphql_data.dig('namespace', 'ciCdSettings') }
  let(:fields) { all_graphql_fields_for('CiCdSettings') }

  let(:query) do
    graphql_query_for(
      'namespace',
      { 'fullPath' => namespace.full_path },
      query_graphql_field('ci_cd_settings', {}, fields)
    )
  end

  let(:execute_query) { post_graphql(query, current_user: current_user) }

  it_behaves_like 'a working graphql query' do
    before do
      namespace.add_maintainer(current_user)

      execute_query
    end

    it 'matches the JSON schema' do
      expect(namespace_settings_response).to match_schema('graphql/ci/namespace_settings')
    end
  end
end
