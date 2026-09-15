# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GroupTransfer', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:target_group) { create(:group) }

  let(:variables) { { id: group.to_global_id.to_s, target_id: target_group.to_global_id.to_s } }
  let(:mutation) { graphql_mutation(:group_transfer, variables, 'errors') }

  before_all do
    group.add_owner(current_user)
    target_group.add_owner(current_user)
  end

  describe 'granular token authorization' do
    before do
      service = instance_double(::Groups::TransferService)
      allow(::Groups::TransferService).to receive(:new).and_return(service)
      allow(service).to receive_messages(schedule_async_transfer: ServiceResponse.success, execute: true)
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :transfer_group do
      let(:user) { current_user }
      let(:boundary_object) { group }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end

  describe 'observable state' do
    it 'transitions the group to transfer_scheduled state', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_mutation_response(:group_transfer)['errors']).to be_empty
      expect(group.reload.state).to eq('transfer_scheduled')
    end

    it 'enqueues a Namespaces::Groups::TransferWorker job' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .to change { Namespaces::Groups::TransferWorker.jobs.size }.by(1)
    end

    context 'when target_id resolves to a non-existent group' do
      let(:variables) do
        { id: group.to_global_id.to_s, target_id: "gid://gitlab/Group/#{non_existing_record_id}" }
      end

      it 'returns a resource not available error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).to include(a_hash_including('message' => a_string_including('Target group not found.')))
      end
    end
  end
end
