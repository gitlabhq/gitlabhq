# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::AppDataSerializer do
  describe '#as_json' do
    subject(:app_data_json) { described_class.new(subscriptions, signed_in).as_json }

    let_it_be(:subscriptions) { create_list(:jira_connect_subscription, 2) }

    let(:signed_in) { false }

    it 'uses the subscription entity' do
      expect(JiraConnect::SubscriptionEntity).to receive(:represent).with(subscriptions)

      app_data_json
    end

    it 'includes a group path with already subscribed namespaces as skip_groups' do
      expected_path = "/api/v4/groups?min_access_level=40&skip_groups%5B%5D=#{subscriptions.first.namespace_id}&skip_groups%5B%5D=#{subscriptions.last.namespace_id}"

      expect(app_data_json).to include(groups_path: expected_path)
    end

    it { is_expected.to include(subscriptions_path: '/-/jira_connect/subscriptions') }
    it { is_expected.to include(login_path: '/-/jira_connect/users') }

    context 'when signed in' do
      let(:signed_in) { true }

      it { is_expected.to include(login_path: nil) }
    end
  end
end
