require 'spec_helper'

describe Gitlab::ReferenceCounter do
  let(:redis) { double('redis') }
  let(:reference_counter_key) { "git-receive-pack-reference-counter:project-1" }
  let(:reference_counter) { described_class.new('project-1') }

  before do
    allow(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis)
  end

  it 'increases and set the expire time of a reference count for a path' do
    expect(redis).to receive(:incr).with(reference_counter_key)
    expect(redis).to receive(:expire).with(reference_counter_key,
        described_class::REFERENCE_EXPIRE_TIME)
    expect(reference_counter.increase).to be(true)
  end

  it 'decreases the reference count for a path' do
    allow(redis).to receive(:decr).and_return(0)
    expect(redis).to receive(:decr).with(reference_counter_key)
    expect(reference_counter.decrease).to be(true)
  end

  it 'warns if attempting to decrease a counter with a value of one or less, and resets the counter' do
    expect(redis).to receive(:decr).and_return(-1)
    expect(redis).to receive(:del)
    expect(Rails.logger).to receive(:warn).with("Reference counter for project-1" \
        " decreased when its value was less than 1. Reseting the counter.")
    expect(reference_counter.decrease).to be(true)
  end

  it 'get the reference count for a path' do
    allow(redis).to receive(:get).and_return(1)
    expect(reference_counter.value).to be(1)
  end
end
