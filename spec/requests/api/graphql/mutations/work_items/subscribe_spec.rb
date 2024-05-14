# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subscribe to a work item', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:subscribed_state) { true }
  let(:mutation_input) { { 'id' => work_item.to_global_id.to_s, 'subscribed' => subscribed_state } }
  let(:mutation) { graphql_mutation(:workItemSubscribe, mutation_input, fields) }
  let(:mutation_response) { graphql_mutation_response(:work_item_subscribe) }
  let(:fields) do
    <<~FIELDS
      workItem {
        widgets {
          type
          ... on WorkItemWidgetNotifications {
            subscribed
          }
        }
      }
      errors
    FIELDS
  end

  context 'when user is not allowed to update subscription work items' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context

  context 'when user has permissions to update its subscription to the work items' do
    let(:current_user) { guest }

    it "subscribe the user to the work item's notifications" do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { work_item.subscribed?(current_user, project) }.to(true)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['workItem']['widgets']).to include({
        'type' => 'NOTIFICATIONS',
        'subscribed' => true
      })
    end

    context 'when unsunscribing' do
      let(:subscribed_state) { false }

      before do
        create(:subscription, project: project, user: current_user, subscribable: work_item, subscribed: true)
      end

      it "unsubscribe the user from the work item's notifications" do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { work_item.subscribed?(current_user, project) }.to(false)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['workItem']['widgets']).to include({
          'type' => 'NOTIFICATIONS',
          'subscribed' => false
        })
      end
    end
  end
end
