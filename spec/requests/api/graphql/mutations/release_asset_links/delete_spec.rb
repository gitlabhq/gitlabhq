# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deletes a release asset link' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:release) { create(:release, project: project) }
  let_it_be(:maintainer) { create(:user).tap { |u| project.add_maintainer(u) } }
  let_it_be(:release_link) { create(:release_link, release: release) }

  let(:current_user) { maintainer }
  let(:mutation_name) { :release_asset_link_delete }
  let(:mutation_arguments) { { id: release_link.to_global_id.to_s } }

  let(:mutation) do
    graphql_mutation(mutation_name, mutation_arguments, <<~FIELDS)
      link {
        id
        name
        url
        linkType
        directAssetUrl
        external
      }
      errors
    FIELDS
  end

  let(:delete_link) { post_graphql_mutation(mutation, current_user: current_user) }
  let(:mutation_response) { graphql_mutation_response(mutation_name)&.with_indifferent_access }

  it 'deletes the release asset link and returns the deleted link', :aggregate_failures do
    delete_link

    expected_response = {
      id: release_link.to_global_id.to_s,
      name: release_link.name,
      url: release_link.url,
      linkType: release_link.link_type.upcase,
      directAssetUrl: end_with(release_link.filepath),
      external: true
    }.with_indifferent_access

    expect(mutation_response[:link]).to match(expected_response)
    expect(mutation_response[:errors]).to eq([])
  end
end
