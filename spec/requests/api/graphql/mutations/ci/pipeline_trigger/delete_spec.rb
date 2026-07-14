# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineTriggerDelete', feature_category: :continuous_integration do
  include GraphqlHelpers

  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:current_user, freeze: false) { build(:user) }
  let_it_be(:project, freeze: false) { build(:project) }

  let(:mutation) { graphql_mutation(:pipeline_trigger_delete, params) }

  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:trigger, freeze: false) { create(:ci_trigger, owner: current_user, project: project) }
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

    it_behaves_like 'authorizing granular token permissions for GraphQL', :delete_trigger do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
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
