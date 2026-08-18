# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::WorkItems::NamespaceWorkItemChanges, feature_category: :planning_views do
  include GraphqlHelpers
  include Graphql::Subscriptions::WorkItems::Helper

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:member) { create(:user, guest_of: group) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:current_user) { member }
  let(:action) { :updated }
  let(:changed_work_item) { work_item }
  let(:payload) { { work_item_id: changed_work_item.id, action: action } }
  let(:namespace) { group }

  let(:subscribe) { namespace_work_item_changes_subscription(namespace, current_user) }
  let(:received) { graphql_dig_at(graphql_data(response[:result]), :namespaceWorkItemChanges) }

  before do
    stub_const('GitlabSchema', Graphql::Subscriptions::ActionCable::MockGitlabSchema)
    Graphql::Subscriptions::ActionCable::MockActionCable.clear_mocks
  end

  subject(:response) do
    subscription_response do
      GitlabSchema.subscriptions.trigger(
        'namespaceWorkItemChanges', { namespace_id: namespace.to_gid }, payload
      )
    end
  end

  context 'when user is unauthorized' do
    let(:current_user) { non_member }

    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  context 'when user is not logged in' do
    let(:current_user) { nil }

    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  context 'when user is a namespace member' do
    it 'receives the changed work item id and action' do
      expect(received['workItemId']).to eq(work_item.to_gid.to_s)
      expect(received['action']).to eq('UPDATED')
    end

    context 'when the action is created' do
      let(:action) { :created }

      it 'serializes the action' do
        expect(received['action']).to eq('CREATED')
      end
    end

    # Goes through the real trigger: filtering happens there, so a hand-built payload would be delivered.
    context 'when a confidential work item changes' do
      let_it_be(:confidential_work_item) { create(:work_item, :confidential, project: project) }

      subject(:response) do
        subscription_response { GraphqlTriggers.work_item_created(confidential_work_item) }
      end

      it 'does not disclose the work item', :aggregate_failures do
        expect(Ability.allowed?(member, :read_work_item, confidential_work_item)).to be(false)

        expect(response).to be_nil
      end
    end

    context 'when the work item was deleted' do
      let(:deleted_work_item) { create(:work_item, project: project) }

      # The record is gone when subscribers deserialize the payload, so it must not carry the work item.
      subject(:response) do
        subscription_response { GraphqlTriggers.work_item_deleted(deleted_work_item) }
      end

      before do
        deleted_work_item.destroy!
      end

      it 'delivers the deleted event', :aggregate_failures do
        expect(received['workItemId']).to eq(deleted_work_item.to_gid.to_s)
        expect(received['action']).to eq('DELETED')
      end
    end
  end

  context 'when the work_items_realtime feature flag is disabled' do
    before do
      stub_feature_flags(work_items_realtime: false)
    end

    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  def namespace_work_item_changes_subscription(namespace, current_user)
    mock_channel = Graphql::Subscriptions::ActionCable::MockActionCable.get_mock_channel

    query = <<~SUBSCRIPTION
      subscription {
        namespaceWorkItemChanges(namespaceId: "#{namespace.to_gid}") {
          workItemId
          action
        }
      }
    SUBSCRIPTION

    GitlabSchema.execute(query, context: { current_user: current_user, channel: mock_channel })

    mock_channel
  end
end
