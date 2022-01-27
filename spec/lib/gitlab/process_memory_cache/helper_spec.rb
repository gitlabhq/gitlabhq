# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ProcessMemoryCache::Helper, :use_clean_rails_memory_store_caching do
  let(:minimal_test_class) do
    Class.new do
      include Gitlab::ProcessMemoryCache::Helper

      def cached_content
        fetch_memory_cache(:cached_content_instance_key) { expensive_computation }
      end

      def clear_cached_content
        invalidate_memory_cache(:cached_content_instance_key)
      end
    end
  end

  before do
    stub_const("MinimalTestClass", minimal_test_class)
  end

  subject { MinimalTestClass.new }

  describe '.fetch_memory_cache' do
    it 'memoizes the result' do
      is_expected.to receive(:expensive_computation).once.and_return(1)

      2.times do
        expect(subject.cached_content).to eq(1)
      end
    end

    it 'resets the cache when the shared key is missing', :aggregate_failures do
      allow(Rails.cache).to receive(:read).with(:cached_content_instance_key).and_return(nil)
      is_expected.to receive(:expensive_computation).thrice.and_return(1, 2, 3)

      3.times do |index|
        expect(subject.cached_content).to eq(index + 1)
      end
    end

    it 'does not set the shared timestamp if it is already present', :redis do
      subject.clear_cached_content
      is_expected.to receive(:expensive_computation).once.and_return(1)

      expect { subject.cached_content }.not_to change { Rails.cache.read(:cached_content_instance_key) }
    end
  end

  describe '.invalidate_memory_cache' do
    it 'invalidates the cache' do
      is_expected.to receive(:expensive_computation).twice.and_return(1, 2)

      expect { subject.clear_cached_content }.to change { subject.cached_content }
    end
  end
end
