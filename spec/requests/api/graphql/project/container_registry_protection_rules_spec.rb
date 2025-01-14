# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting the containers protection rules linked to a project', :aggregate_failures, feature_category: :container_registry do
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { project.owner }

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:containerProtectionRepositoryRules, of: 'ContainerProtectionRepositoryRule')
    )
  end

  let(:protection_rules) { graphql_data_at(:project, :containerProtectionRepositoryRules, :nodes) }

  subject(:send_graqhql_query) { post_graphql(query, current_user: user) }

  context 'with authorized user owner' do
    before do
      send_graqhql_query
    end

    context 'with container protection rule' do
      let_it_be(:container_protection_rule) { create(:container_registry_protection_rule, project: project) }

      it_behaves_like 'a working graphql query'

      it 'returns only on containersProtectionRule' do
        expect(protection_rules.count).to eq 1
      end

      it 'returns all containers protection rule fields' do
        expect(protection_rules).to include(
          hash_including(
            'repositoryPathPattern' => container_protection_rule.repository_path_pattern,
            'minimumAccessLevelForDelete' => 'MAINTAINER',
            'minimumAccessLevelForPush' => 'MAINTAINER'
          )
        )
      end
    end

    context 'without container protection rule' do
      it_behaves_like 'a working graphql query'

      it 'returns no containersProtectionRule' do
        expect(protection_rules).to be_empty
      end
    end
  end

  context 'with unauthorized user' do
    let_it_be(:user) { create(:user, developer_of: project) }

    before do
      send_graqhql_query
    end

    it_behaves_like 'a working graphql query'

    it 'returns no container protection rules' do
      expect(protection_rules).to be_empty
    end
  end
end
