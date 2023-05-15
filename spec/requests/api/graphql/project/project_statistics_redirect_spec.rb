# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'rendering project storage type routes', feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  let(:query) do
    graphql_query_for('project',
      { 'fullPath' => project.full_path },
      "statisticsDetailsPaths { #{all_graphql_fields_for('ProjectStatisticsRedirect')} }")
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: user)
    end
  end

  shared_examples 'valid routes for storage type' do
    it 'contains all keys' do
      post_graphql(query, current_user: user)

      expect(graphql_data['project']['statisticsDetailsPaths'].keys).to match_array(
        %w[repository buildArtifacts wiki packages snippets containerRegistry]
      )
    end

    it 'contains valid paths' do
      repository_url = Gitlab::Routing.url_helpers.project_tree_url(project, "master")
      wiki_url = Gitlab::Routing.url_helpers.project_wikis_pages_url(project)
      build_artifacts_url = Gitlab::Routing.url_helpers.project_artifacts_url(project)
      packages_url = Gitlab::Routing.url_helpers.project_packages_url(project)
      snippets_url = Gitlab::Routing.url_helpers.project_snippets_url(project)
      container_registry_url = Gitlab::Routing.url_helpers.project_container_registry_index_url(project)

      post_graphql(query, current_user: user)

      expect(graphql_data['project']['statisticsDetailsPaths'].values).to match_array [repository_url,
        wiki_url,
        build_artifacts_url,
        packages_url,
        snippets_url,
        container_registry_url]
    end
  end

  context 'when project is public' do
    it_behaves_like 'valid routes for storage type'

    context 'when user is nil' do
      let_it_be(:user) { nil }

      it_behaves_like 'valid routes for storage type'
    end
  end

  context 'when project is private' do
    let_it_be(:project) { create(:project, :private) }

    before do
      project.add_reporter(user)
    end

    it_behaves_like 'valid routes for storage type'

    context 'when user is nil' do
      it 'hides statisticsDetailsPaths for nil users' do
        post_graphql(query, current_user: nil)

        expect(graphql_data['project']).to be_blank
      end
    end
  end
end
