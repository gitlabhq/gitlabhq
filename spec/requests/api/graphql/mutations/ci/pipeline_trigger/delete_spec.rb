# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineTriggerDelete', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:current_user) { build(:user) }
  let_it_be(:project) { build(:project) }

  let(:mutation) { graphql_mutation(:pipeline_trigger_delete, params) }

  let_it_be(:trigger) { create(:ci_trigger, owner: current_user, project: project) }
  let(:id) { trigger.to_global_id.to_s }

  let(:params) do
    {
      id: id
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

    context 'when the id is invalid' do
      let(:id) { non_existing_record_id }

      it_behaves_like 'an invalid argument to the mutation', argument_name: :id

      it 'does not delete a pipeline trigger token' do
        expect { subject }.not_to change { project.triggers.count }
        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'when the id is nil' do
      let(:id) { nil }

      it_behaves_like 'an invalid argument to the mutation', argument_name: :id

      it 'does not delete a pipeline trigger token' do
        expect { subject }.not_to change { project.triggers.count }
        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'when the params are valid' do
      it_behaves_like 'a working GraphQL mutation'

      it 'deletes the pipeline trigger token' do
        expect { subject }.to change { project.triggers.count }.by(-1)
      end
    end
  end
end
