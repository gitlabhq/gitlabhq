# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::WorkItems::SavedViewUpdated, feature_category: :planning_views do
  include GraphqlHelpers
  include Graphql::Subscriptions::WorkItems::Helper

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:author) { create(:user, guest_of: group) }
  let_it_be(:member) { create(:user, guest_of: group) }
  let_it_be(:non_member) { create(:user) }

  let_it_be_with_reload(:saved_view) do
    create(:saved_view,
      namespace: group,
      author: author,
      private: false,
      sort: 'created_asc',
      display_settings: { 'viewMode' => 'board' }
    )
  end

  let(:current_user) { member }
  let(:subscribe) { saved_view_updated_subscription(saved_view, current_user) }
  let(:received) { graphql_dig_at(graphql_data(response[:result]), :workItemSavedViewUpdated) }

  before do
    stub_const('GitlabSchema', Graphql::Subscriptions::ActionCable::MockGitlabSchema)
    Graphql::Subscriptions::ActionCable::MockActionCable.clear_mocks
  end

  subject(:response) do
    subscription_response do
      GraphqlTriggers.work_item_saved_view_updated(saved_view)
    end
  end

  context 'when the user is not a namespace member' do
    let(:current_user) { non_member }

    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  context 'when the user is not logged in' do
    let(:current_user) { nil }

    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  context 'when the saved view is private' do
    before do
      saved_view.update!(private: true)
    end

    it 'does not deliver to a member who is not the author' do
      expect(response).to be_nil
    end

    context 'when the subscriber is the author' do
      let(:current_user) { author }

      it 'delivers the saved view' do
        expect(received['id']).to eq(saved_view.to_gid.to_s)
      end
    end
  end

  context 'when the user can read the saved view' do
    it 'receives the updated saved view configuration' do
      expect(received['id']).to eq(saved_view.to_gid.to_s)
      expect(received['displaySettings']).to eq({ 'viewMode' => 'board' })
      expect(received['sort']).to eq('CREATED_ASC')
      expect(received['isPrivate']).to be(false)
    end

    it 'resolves subscribed against the recipient, not the user who made the change' do
      create(:user_saved_view, saved_view: saved_view, user: member)

      expect(received['subscribed']).to be(true)
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

  context 'when the work_items_realtime_broadcast feature flag is disabled' do
    before do
      stub_feature_flags(work_items_realtime_broadcast: false)
    end

    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  def saved_view_updated_subscription(saved_view, current_user)
    mock_channel = Graphql::Subscriptions::ActionCable::MockActionCable.get_mock_channel

    query = <<~SUBSCRIPTION
      subscription {
        workItemSavedViewUpdated(savedViewId: "#{saved_view.to_gid}") {
          id
          displaySettings
          sort
          isPrivate
          subscribed
        }
      }
    SUBSCRIPTION

    GitlabSchema.execute(query, context: { current_user: current_user, channel: mock_channel })

    mock_channel
  end
end
