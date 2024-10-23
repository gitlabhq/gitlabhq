# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting the packages protection rules linked to a project', :aggregate_failures, feature_category: :package_registry do
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { project.owner }

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:packagesProtectionRules, of: 'PackagesProtectionRule')
    )
  end

  subject { post_graphql(query, current_user: user) }

  context 'with authorized user owner' do
    before do
      subject
    end

    context 'with package protection rule' do
      let_it_be(:package_protection_rule) { create(:package_protection_rule, project: project) }

      it_behaves_like 'a working graphql query'

      it 'returns only on PackagesProtectionRule' do
        expect(graphql_data_at(:project, :packagesProtectionRules, :nodes).count).to eq 1
      end

      it 'returns all packages protection rule fields' do
        expect(graphql_data_at(:project, :packagesProtectionRules, :nodes)).to include(
          hash_including(
            'packageNamePattern' => package_protection_rule.package_name_pattern,
            'packageType' => 'NPM',
            'minimumAccessLevelForPush' => 'MAINTAINER'
          )
        )
      end
    end

    context 'without package protection rule' do
      it_behaves_like 'a working graphql query'

      it 'returns no PackagesProtectionRule' do
        expect(graphql_data_at(:project, :packagesProtectionRules, :nodes)).to eq []
      end
    end
  end

  context 'with unauthorized user' do
    let_it_be(:user) { create(:user, developer_of: project) }

    before do
      subject
    end

    it_behaves_like 'a working graphql query'

    it 'returns no package protection rules' do
      expect(graphql_data_at(:project, :packagesProtectionRules, :nodes)).to eq []
    end
  end
end
