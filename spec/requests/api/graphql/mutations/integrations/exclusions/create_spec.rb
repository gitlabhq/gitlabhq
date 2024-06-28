# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Integrations::Exclusions::Create, feature_category: :integrations do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project, :in_subgroup) }
  let_it_be(:admin_user) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let(:current_user) { admin_user }
  let(:mutation) { graphql_mutation(:integration_exclusion_create, args, fields) }
  let(:args) do
    {
      'integrationName' => 'BEYOND_IDENTITY',
      'projectIds' => project_ids,
      'groupIds' => group_ids
    }
  end

  let(:fields) do
    <<~FIELDS
    exclusions{
      project{
        id
        name
        avatarUrl
      }
      group{
        id
        name
        avatarUrl
      }
    }
    FIELDS
  end

  let(:project_ids) { [project.to_global_id.to_s] }
  let(:group_ids) { [] }

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

    it 'creates inactive integrations for the projects' do
      expect { resolve_mutation }.to change { Integration.count }.from(0).to(1)
    end

    context 'when integrations exist for the projects' do
      let!(:instance_exclusion) { create(:beyond_identity_integration) }
      let!(:existing_exclusion) do
        create(:beyond_identity_integration, project: project2, active: false, inherit_from_id: instance_exclusion.id,
          instance: false)
      end

      let(:project_ids) { [project, project2].map { |p| p.to_global_id.to_s } }

      it 'updates existing integrations and creates integrations for projects' do
        expect { resolve_mutation }.to change { Integration.count }.from(2).to(3)
        existing_exclusion.reload
        expect(existing_exclusion).not_to be_active
        expect(existing_exclusion.inherit_from_id).to be_nil
      end

      context 'when creating exclusions for groups' do
        let(:args) do
          {
            'integrationName' => 'BEYOND_IDENTITY',
            'projectIds' => project_ids,
            'groupIds' => [project2.group.to_global_id.to_s]
          }
        end

        it 'updates existing integrations and creates integrations for projects', :sidekiq_inline do
          expect { resolve_mutation }.to change { Integration.count }.from(2).to(4)
          expect(graphql_data['integrationExclusionCreate']['exclusions'].length).to eq(2)
          expect(graphql_data['integrationExclusionCreate']['exclusions']).to include(a_hash_including({
            'project' => nil, 'group' => a_hash_including({ 'id' => project2.group.to_global_id.to_s })
          }))
          expect(graphql_data['integrationExclusionCreate']['exclusions']).to include(a_hash_including({
            'project' => a_hash_including({ 'id' => project.to_global_id.to_s }), 'group' => nil
          }))
          expect(existing_exclusion).not_to be_active
          expect(existing_exclusion.inherit_from_id).to be_present
        end
      end
    end

    describe 'validations' do
      context 'when there are too many project ids in the request' do
        let(:project_ids) { (1..101).map { |id| "gid://gitlab/Project/#{id}" } }

        it 'responds with an error without changing exclusions' do
          expect(Integrations::Exclusions::CreateService).not_to receive(:new)
          resolve_mutation
          expect(graphql_errors).to include(a_hash_including('message' => "projectIds is too long (maximum is 100)"))
        end
      end

      context 'when there are too many group ids in the request' do
        let(:group_ids) { (1..101).map { |id| "gid://gitlab/Group/#{id}" } }

        it 'responds with an error without changing exclusions' do
          expect(Integrations::Exclusions::CreateService).not_to receive(:new)
          resolve_mutation
          expect(graphql_errors).to include(a_hash_including('message' => "groupIds is too long (maximum is 100)"))
        end
      end
    end
  end
end
