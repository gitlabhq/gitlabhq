# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProjectTransfer', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:target_namespace) { create(:group) }

  let(:variables) { { id: project.to_global_id.to_s, namespace_id: target_namespace.to_global_id.to_s } }
  let(:mutation) { graphql_mutation(:project_transfer, variables, 'project { id } errors') }

  before_all do
    project.add_owner(current_user)
    target_namespace.add_owner(current_user)
  end

  describe 'granular token authorization' do
    before do
      service = instance_double(::Projects::TransferService)
      allow(::Projects::TransferService).to receive(:new).and_return(service)
      allow(service).to receive_messages(schedule_async_transfer: ServiceResponse.success, execute: true)
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :transfer_project do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end

  describe 'observable state' do
    it 'transitions the project namespace to transfer_scheduled state', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_mutation_response(:project_transfer)['errors']).to be_empty
      expect(project.project_namespace.reload.state).to eq('transfer_scheduled')
    end

    it 'enqueues a Projects::TransferWorker job' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .to change { Projects::TransferWorker.jobs.size }.by(1)
    end

    context 'when namespace_id resolves to a ProjectNamespace' do
      let(:variables) do
        { id: project.to_global_id.to_s, namespace_id: project.project_namespace.to_global_id.to_s }
      end

      it 'returns an error and the project', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        response = graphql_mutation_response(:project_transfer)
        expect(response['errors']).to contain_exactly(
          'Target namespace must be a group or user namespace, not a project namespace.'
        )
        expect(response['project']).not_to be_nil
      end
    end
  end
end
