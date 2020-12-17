# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::SearchCounter, :clean_gitlab_redis_shared_state do
  shared_examples_for 'usage counter with totals' do |counter|
    it 'increments counter and returns total count' do
      expect(described_class.read(counter)).to eq(0)

      2.times { described_class.count(counter) }

      expect(described_class.read(counter)).to eq(2)
    end
  end

  context 'all_searches counter' do
    it_behaves_like 'usage counter with totals', :all_searches
  end

  context 'navbar_searches counter' do
    it_behaves_like 'usage counter with totals', :navbar_searches
  end

  describe '.fetch_supported_event' do
    subject { described_class.fetch_supported_event(event_name) }

    let(:event_name) { 'all_searches' }

    it { is_expected.to eq 'all_searches' }
  end
end
