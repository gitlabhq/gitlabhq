# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::AppDataSerializer do
  describe '#as_json' do
    subject(:app_data_json) { described_class.new(subscriptions).as_json }

    let_it_be(:subscriptions) { create_list(:jira_connect_subscription, 2) }

    it 'uses the subscription entity' do
      expect(JiraConnect::SubscriptionEntity).to receive(:represent).with(subscriptions)

      app_data_json
    end

    it 'includes a group path with already subscribed namespaces as comma-separated skip_groups' do
      expected_path = "/api/v4/groups?min_access_level=40&skip_groups=#{subscriptions.first.namespace_id}%2C#{subscriptions.last.namespace_id}"

      expect(app_data_json).to include(groups_path: expected_path)
    end

    it { is_expected.to include(subscriptions_path: '/-/jira_connect/subscriptions') }
  end
end
