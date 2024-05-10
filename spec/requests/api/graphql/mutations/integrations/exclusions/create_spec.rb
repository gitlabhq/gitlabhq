# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Integrations::Exclusions::Create, feature_category: :integrations do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:admin_user) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let(:current_user) { admin_user }
  let(:mutation) { graphql_mutation(:integration_exclusion_create, args) }
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
    end
  end
end
