# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::GroupEntity do
  subject do
    described_class.new(subscription.namespace).as_json
  end

  let(:subscription) { create(:jira_connect_subscription) }

  it 'contains all necessary elements of the group', :aggregate_failures do
    expect(subject[:name]).to eq(subscription.namespace.name)
    expect(subject[:avatar_url]).to eq(subscription.namespace.avatar_url)
    expect(subject[:full_name]).to eq(subscription.namespace.full_name)
    expect(subject[:description]).to eq(subscription.namespace.description)
  end
end
