# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineTriggerUpdate', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:current_user, freeze: false) { build(:user) }
  let_it_be(:project, freeze: false) { build(:project) }

  let(:mutation) { graphql_mutation(:pipeline_trigger_update, params) }
  let_it_be(:old_description) { "Boring old description." }
  let(:new_description) { 'Awesome new description!' }
  let_it_be(:trigger, freeze: false) do
    create(:ci_trigger, owner: current_user, project: project, description: old_description)
  end

  let(:params) do
    {
      id: trigger.to_global_id.to_s,
      description: new_description
    }
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  context 'when unauthorized' do
    it_behaves_like 'a mutation on an unauthorized resource'
  end

  context 'when authorized' do
    before_all do
      project.add_owner(current_user)
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :update_trigger do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:mutation) do
        graphql_mutation(:pipeline_trigger_update, { id: trigger.to_global_id.to_s, description: new_description },
          'errors')
      end

      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end

    context 'when the params are invalid' do
      let(:new_description) { nil }

      it_behaves_like 'an invalid argument to the mutation', argument_name: 'description'

      it 'does not update a pipeline trigger token' do
        expect { subject }.not_to change { trigger }
        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'when the params are valid' do
      it_behaves_like 'a working GraphQL mutation'

      it 'updates the pipeline trigger token' do
        expect { subject }.to change { trigger.reload.description }.to(new_description)

        expect(graphql_errors).to be_blank
      end

      it 'returns the updated trigger token' do
        subject

        expect(graphql_data_at(:pipeline_trigger_update, :pipeline_trigger)).to match a_hash_including(
          'owner' => a_hash_including(
            'id' => current_user.to_global_id.to_s,
            'username' => current_user.username,
            'name' => current_user.name
          ),
          'description' => new_description,
          "canAccessProject" => true,
          "hasTokenExposed" => true,
          "lastUsed" => nil
        )
      end
    end
  end
end
