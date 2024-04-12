# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a new release asset link', feature_category: :release_orchestration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:release) { create(:release, project: project, tag: 'v13.10') }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:current_user) { developer }

  let(:mutation_name) { :release_asset_link_create }

  let(:mutation_arguments) do
    {
      projectPath: project.full_path,
      tagName: release.tag,
      name: 'awesome-app.dmg',
      url: 'https://example.com/download/awesome-app.dmg',
      directAssetPath: '/binaries/awesome-app.dmg',
      linkType: 'PACKAGE'
    }
  end

  let(:mutation) do
    graphql_mutation(mutation_name, mutation_arguments, <<~FIELDS)
      link {
        id
        name
        url
        linkType
        directAssetUrl
      }
      errors
    FIELDS
  end

  let(:create_link) { post_graphql_mutation(mutation, current_user: current_user) }
  let(:mutation_response) { graphql_mutation_response(mutation_name)&.with_indifferent_access }

  it 'creates and returns a new asset link associated to the provided release', :aggregate_failures do
    create_link

    expected_response = {
      id: start_with("gid://gitlab/Releases::Link/"),
      name: mutation_arguments[:name],
      url: mutation_arguments[:url],
      linkType: mutation_arguments[:linkType],
      directAssetUrl: end_with(mutation_arguments[:directAssetPath])
    }.with_indifferent_access

    expect(mutation_response[:link]).to include(expected_response)
    expect(mutation_response[:errors]).to eq([])
  end
end
