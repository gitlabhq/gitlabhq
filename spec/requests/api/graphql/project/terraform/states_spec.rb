# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'query terraform states', feature_category: :infrastructure_as_code do
  include GraphqlHelpers
  include ::API::Helpers::RelatedResourcesHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:terraform_state) { create(:terraform_state, :with_version, :locked, project: project) }
  let_it_be(:latest_version) { terraform_state.latest_version }

  let(:query) do
    graphql_query_for(
      :project,
      { fullPath: project.full_path },
      %(
        terraformStates {
          count
          nodes {
            id
            name
            lockedAt
            createdAt
            updatedAt

            latestVersion {
              id
              downloadPath
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
          }
        }
      )
    )
  end

  let(:current_user) { project.creator }
  let(:data) { graphql_data.dig('project', 'terraformStates') }

  before do
    post_graphql(query, current_user: current_user)
  end

  it 'returns terraform state data' do
    download_path = expose_path(
      api_v4_projects_terraform_state_versions_path(
        id: project.id,
        name: terraform_state.name,
        serial: latest_version.version
      )
    )

    expect(data['nodes']).to contain_exactly a_graphql_entity_for(
      terraform_state, :name,
      'lockedAt' => terraform_state.locked_at.iso8601,
      'createdAt' => terraform_state.created_at.iso8601,
      'updatedAt' => terraform_state.updated_at.iso8601,
      'lockedByUser' => a_graphql_entity_for(terraform_state.locked_by_user),
      'latestVersion' => a_graphql_entity_for(
        latest_version,
        'serial' => eq(latest_version.version),
        'downloadPath' => eq(download_path),
        'createdAt' => eq(latest_version.created_at.iso8601),
        'updatedAt' => eq(latest_version.updated_at.iso8601),
        'createdByUser' => a_graphql_entity_for(latest_version.created_by_user),
        'job' => { 'name' => eq(latest_version.build.name) }
      )
    )
  end

  it 'returns count of terraform states' do
    count = data['count']
    expect(count).to be(project.terraform_states.size)
  end

  context 'unauthorized users' do
    let(:current_user) { nil }

    it { expect(data).to be_nil }
  end

  describe 'protectionRuleExists' do
    let_it_be(:terraform_state_protection_rule) do
      create(:terraform_state_protection_rule, project: project, state_name: terraform_state.name)
    end

    let(:fields) do
      %(
        terraformStates {
          nodes {
            name
            protectionRuleExists
          }
        }
      )
    end

    let(:query) do
      graphql_query_for(:project, { fullPath: project.full_path }, fields)
    end

    describe 'efficient database queries' do
      let_it_be(:project2) { create(:project) }
      let_it_be(:terraform_states_project2) do
        create_list(:terraform_state, 4, project: project2)
      end

      let_it_be(:terraform_state_protection_rule_project2) do
        create(:terraform_state_protection_rule, project: project2,
          state_name: terraform_states_project2.first.name)
      end

      let_it_be(:user1) { create(:user, maintainer_of: project) }
      let_it_be(:user2) { create(:user, maintainer_of: project2) }

      it 'avoids N+1 database queries' do
        control_count = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: user1) }

        query2 = graphql_query_for(:project, { fullPath: project2.full_path }, fields)
        expect { post_graphql(query2, current_user: user2) }.not_to exceed_query_limit(control_count)
      end
    end

    context 'when protection rule exists for the terraform state' do
      it 'returns true for protected state and false for unprotected state' do
        unprotected_state = create(:terraform_state, project: project)

        post_graphql(query, current_user: current_user)

        states_data = data['nodes']
        protected_state_data = states_data.find { |s| s['name'] == terraform_state.name }
        unprotected_state_data = states_data.find { |s| s['name'] == unprotected_state.name }

        expect(protected_state_data['protectionRuleExists']).to be true
        expect(unprotected_state_data['protectionRuleExists']).to be false
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(protected_terraform_states: false)
      end

      it 'returns false for all states' do
        post_graphql(query, current_user: current_user)

        expect(data['nodes']).to all(include('protectionRuleExists' => false))
      end
    end
  end
end
