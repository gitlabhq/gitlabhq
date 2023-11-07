# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'query a single terraform state', feature_category: :infrastructure_as_code do
  include GraphqlHelpers
  include ::API::Helpers::RelatedResourcesHelpers

  let_it_be(:terraform_state) { create(:terraform_state, :with_version, :locked) }

  let(:latest_version) { terraform_state.latest_version }
  let(:project) { terraform_state.project }
  let(:current_user) { project.creator }
  let(:data) { graphql_data.dig('project', 'terraformState') }

  let(:query) do
    graphql_query_for(
      :project,
      { fullPath: project.full_path },
      query_graphql_field(
        :terraformState,
        { name: terraform_state.name },
        %(
          id
          name
          lockedAt
          createdAt
          updatedAt

          latestVersion {
            id
            serial
            createdAt
            updatedAt

            createdByUser {
              id
            }

            job {
              name
            }
          }

          lockedByUser {
            id
          }
        )
      )
    )
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns terraform state data' do
    expect(data).to match a_graphql_entity_for(
      terraform_state,
      :name,
      'lockedAt' => terraform_state.locked_at.iso8601,
      'createdAt' => terraform_state.created_at.iso8601,
      'updatedAt' => terraform_state.updated_at.iso8601,
      'lockedByUser' => a_graphql_entity_for(terraform_state.locked_by_user),
      'latestVersion' => a_graphql_entity_for(
        latest_version,
        'serial' => eq(latest_version.version),
        'createdAt' => eq(latest_version.created_at.iso8601),
        'updatedAt' => eq(latest_version.updated_at.iso8601),
        'createdByUser' => a_graphql_entity_for(latest_version.created_by_user),
        'job' => { 'name' => eq(latest_version.build.name) }
      )
    )
  end

  context 'unauthorized users' do
    let(:current_user) { nil }

    it { expect(data).to be_nil }
  end
end
