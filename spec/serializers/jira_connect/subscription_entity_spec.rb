# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SubscriptionEntity, feature_category: :team_planning do
  subject do
    described_class.new(subscription).as_json
  end

  let(:subscription) { build_stubbed(:jira_connect_subscription) }

  it 'contains all necessary elements of the subscription', :aggregate_failures do
    expect(subject).to include(:created_at)
    expect(subject[:unlink_path]).to eq("/-/jira_connect/subscriptions/#{subscription.id}")
    expect(subject[:group]).to eq(
      name: subscription.namespace.name,
      avatar_url: subscription.namespace.avatar_url,
      full_name: subscription.namespace.full_name,
      description: subscription.namespace.description
    )
  end
end
