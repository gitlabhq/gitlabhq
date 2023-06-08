# frozen_string_literal: true

require "spec_helper"

RSpec.describe Subscriptions::WorkItemUpdated, feature_category: :team_planning do
  include GraphqlHelpers
  include Graphql::Subscriptions::WorkItems::Helper

  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:task) { create(:work_item, :task, project: project) }

  let(:current_user) { nil }
  let(:subscribe) { work_item_subscription('workItemUpdated', task, current_user) }
  let(:updated_work_item) { graphql_dig_at(graphql_data(response[:result]), :workItemUpdated) }

  before do
    stub_const('GitlabSchema', Graphql::Subscriptions::ActionCable::MockGitlabSchema)
    Graphql::Subscriptions::ActionCable::MockActionCable.clear_mocks
    project.add_reporter(reporter)
  end

  subject(:response) do
    subscription_response do
      GraphqlTriggers.work_item_updated(task)
    end
  end

  context 'when user is unauthorized' do
    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  context 'when user is authorized' do
    let(:current_user) { reporter }

    it 'receives updated work_item data' do
      expect(updated_work_item['id']).to eq(task.to_gid.to_s)
      expect(updated_work_item['iid']).to eq(task.iid.to_s)
    end
  end
end
