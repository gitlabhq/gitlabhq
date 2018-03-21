require 'spec_helper'

describe Gitlab::ActionRateLimiter do
  let(:redis) { double('redis') }
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:key) { [user, project] }
  let(:cache_key) { "action_rate_limiter:test_action:user:#{user.id}:project:#{project.id}" }

  subject { described_class.new(action: :test_action, expiry_time: 100) }

  before do
    allow(Gitlab::Redis::Cache).to receive(:with).and_yield(redis)
  end

  it 'increases the throttle count and sets the expire time' do
    expect(redis).to receive(:incr).with(cache_key).and_return(1)
    expect(redis).to receive(:expire).with(cache_key, 100)

    expect(subject.throttled?(key, 1)).to be false
  end

  it 'returns true if the key is throttled' do
    expect(redis).to receive(:incr).with(cache_key).and_return(2)
    expect(redis).not_to receive(:expire)

    expect(subject.throttled?(key, 1)).to be true
  end
end
