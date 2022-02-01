# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a tracked jetbrains unique action' do |event|
  before do
    stub_application_setting(usage_ping_enabled: true)
  end

  def count_unique(date_from:, date_to:)
    Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: action, start_date: date_from, end_date: date_to)
  end

  it 'tracks when the user agent is from jetbrains' do
    aggregate_failures do
      user_agent = { user_agent: 'gitlab-jetbrains-plugin/0.0.1 intellij-idea/2021.2.4 java/11.0.13 mac-os-x/aarch64/12.1' }

      expect(track_action(user: user1, **user_agent)).to be_truthy
      expect(track_action(user: user1, **user_agent)).to be_truthy
      expect(track_action(user: user2, **user_agent)).to be_truthy

      expect(count_unique(date_from: time - 1.week, date_to: time + 1.week)).to eq(2)
    end
  end

  it 'does not track when the user agent is not from jetbrains' do
    aggregate_failures do
      user_agent = { user_agent: 'normal_user_agent' }

      expect(track_action(user: user1, **user_agent)).to be_falsey
      expect(track_action(user: user1, **user_agent)).to be_falsey
      expect(track_action(user: user2, **user_agent)).to be_falsey

      expect(count_unique(date_from: time - 1.week, date_to: time + 1.week)).to eq(0)
    end
  end

  it 'does not track if user agent is not present' do
    expect(track_action(user: nil, user_agent: nil)).to be_nil
  end

  it 'does not track if user is not present' do
    user_agent = { user_agent: 'gitlab-jetbrains-plugin/0.0.1 intellij-idea/2021.2.4 java/11.0.13 mac-os-x/aarch64/12.1' }

    expect(track_action(user: nil, **user_agent)).to be_nil
  end
end

RSpec.describe Gitlab::UsageDataCounters::JetBrainsPluginActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:time) { Time.current }

  context 'when tracking a jetbrains api request' do
    it_behaves_like 'a tracked jetbrains unique action' do
      let(:action) { described_class::JETBRAINS_API_REQUEST_ACTION }

      def track_action(params)
        described_class.track_api_request_when_trackable(**params)
      end
    end
  end
end
