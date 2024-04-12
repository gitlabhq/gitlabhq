# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an existing release asset link', feature_category: :release_orchestration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:release) { create(:release, project: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let_it_be(:release_link) do
    create(
      :release_link,
      release: release,
      name: 'link name',
      url: 'https://example.com/url',
      filepath: '/permanent/path',
      link_type: 'package'
    )
  end

  let(:current_user) { developer }

  let(:mutation_name) { :release_asset_link_update }

  let(:mutation_arguments) do
    {
      id: release_link.to_global_id.to_s,
      name: 'updated name',
      url: 'https://example.com/updated',
      directAssetPath: '/updated/path',
      linkType: 'IMAGE'
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

  let(:update_link) { post_graphql_mutation(mutation, current_user: current_user) }
  let(:mutation_response) { graphql_mutation_response(mutation_name)&.with_indifferent_access }

  it 'updates and existing release asset link and returns the updated link', :aggregate_failures do
    update_link

    expected_response = {
      id: mutation_arguments[:id],
      name: mutation_arguments[:name],
      url: mutation_arguments[:url],
      linkType: mutation_arguments[:linkType],
      directAssetUrl: end_with(mutation_arguments[:directAssetPath])
    }.with_indifferent_access

    expect(mutation_response[:link]).to include(expected_response)
    expect(mutation_response[:errors]).to eq([])
  end
end
