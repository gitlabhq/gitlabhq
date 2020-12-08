# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::GuestPackageEventCounter, :clean_gitlab_redis_shared_state do
  shared_examples_for 'usage counter with totals' do |counter|
    it 'increments counter and returns total count' do
      expect(described_class.read(counter)).to eq(0)

      2.times { described_class.count(counter) }

      expect(described_class.read(counter)).to eq(2)
    end
  end

  it 'includes the right events' do
    expect(described_class::KNOWN_EVENTS.size).to eq 33
  end

  described_class::KNOWN_EVENTS.each do |event|
    it_behaves_like 'usage counter with totals', event
  end

  describe '.fetch_supported_event' do
    subject { described_class.fetch_supported_event(event_name) }

    let(:event_name) { 'package_guest_i_package_composer_guest_push' }

    it { is_expected.to eq 'i_package_composer_guest_push' }
  end
end
