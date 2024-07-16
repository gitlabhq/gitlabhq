# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Integrations::Exclusions::Delete, feature_category: :integrations do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project, :in_subgroup) }
  let_it_be(:admin_user) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let(:current_user) { admin_user }
  let(:mutation) { graphql_mutation(:integration_exclusion_delete, args) }
  let(:args) do
    {
      'integrationName' => 'BEYOND_IDENTITY',
      'projectIds' => project_ids
    }
  end

  let(:project_ids) { [project.to_global_id.to_s] }

  subject(:resolve_mutation) { post_graphql_mutation(mutation, current_user: current_user) }

  context 'when the user is not authorized' do
    let(:current_user) { user }

    it 'responds with an error' do
      resolve_mutation
      expect(graphql_errors.first['message']).to eq(
        Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
      )
    end
  end

  context 'when the user is authorized' do
    let(:current_user) { admin_user }

    it 'returns an empty array' do
      resolve_mutation
      expect(graphql_data['integrationExclusionDelete']['exclusions']).to eq([])
    end

    context 'and there are integrations' do
      let!(:existing_exclusion) do
        create(:beyond_identity_integration, project: project, active: false, inherit_from_id: nil,
          instance: false)
      end

      context 'and the integration is active for the instance' do
        let!(:instance_integration) { create(:beyond_identity_integration) }

        context 'and there is a group exclusion', :sidekiq_inline do
          let!(:group_exclusion) do
            create(:beyond_identity_integration, group: project2.root_namespace, active: false, inherit_from_id: nil,
              instance: false)
          end

          let(:args) do
            {
              'integrationName' => 'BEYOND_IDENTITY',
              'projectIds' => project_ids,
              'groupIds' => [project2.root_namespace.to_global_id.to_s]
            }
          end

          it 'enables the integration for the specified project' do
            resolve_mutation

            existing_exclusion.reload
            expect(existing_exclusion).to be_activated
            expect(existing_exclusion.inherit_from_id).to eq(instance_integration.id)
            expect(project2.beyond_identity_integration).to be_activated
            expect(project2.beyond_identity_integration.inherit_from_id).to eq(instance_integration.id)
            exclusion_response = graphql_data['integrationExclusionDelete']['exclusions']
            expect(exclusion_response).to include(a_hash_including({ 'group' => nil,
'project' => a_hash_including({ 'id' => project.to_global_id.to_s }) }))
            expect(exclusion_response).to include(a_hash_including({ 'project' => nil,
'group' => a_hash_including({ 'id' => project2.root_namespace.to_global_id.to_s }) }))
          end
        end

        it 'enables the integration for the specified project' do
          resolve_mutation

          existing_exclusion.reload
          expect(existing_exclusion).to be_activated
          expect(existing_exclusion.inherit_from_id).to eq(instance_integration.id)
          exclusion_response = graphql_data['integrationExclusionDelete']['exclusions'][0]
          expect(exclusion_response['project']['id']).to eq(project.to_global_id.to_s)
        end
      end

      it 'deletes the integration' do
        expect { resolve_mutation }.to change { Integration.count }.from(1).to(0)
        expect(graphql_errors).to be_nil
      end
    end
  end
end
