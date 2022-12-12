# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'nuget package details', feature_category: :package_registry do
  include GraphqlHelpers
  include_context 'package details setup'

  let_it_be(:package) { create(:nuget_package, :last_downloaded_at, :with_metadatum, project: project) }
  let_it_be(:dependency_link) { create(:packages_dependency_link, :with_nuget_metadatum, package: package) }

  let(:metadata) { query_graphql_fragment('NugetMetadata') }
  let(:dependency_link_response) { graphql_data_at(:package, :dependency_links, :nodes, 0) }
  let(:dependency_response) { graphql_data_at(:package, :dependency_links, :nodes, 0, :dependency) }

  subject { post_graphql(query, current_user: user) }

  before do
    subject
  end

  it_behaves_like 'a package detail'
  it_behaves_like 'a package with files'

  it 'has the correct metadata' do
    expect(metadata_response).to match a_graphql_entity_for(
      package.nuget_metadatum, :license_url, :project_url, :icon_url
    )
  end

  it 'has dependency links' do
    expect(dependency_link_response).to match a_graphql_entity_for(
      dependency_link,
      'dependencyType' => dependency_link.dependency_type.upcase
    )

    expect(dependency_response).to match a_graphql_entity_for(
      dependency_link.dependency, :name, :version_pattern
    )
  end

  it 'avoids N+1 queries' do
    first_user = create(:user)
    second_user = create(:user)

    control_count = ActiveRecord::QueryRecorder.new do
      post_graphql(query, current_user: first_user)
    end

    create_list(:packages_dependency_link, 10, :with_nuget_metadatum, package: package)

    expect do
      post_graphql(query, current_user: second_user)
    end.not_to exceed_query_limit(control_count)

    expect(response).to have_gitlab_http_status(:ok)
  end
end
