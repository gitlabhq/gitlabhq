# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveCaching::LowUrgencyWorker, feature_category: :redis do
  it_behaves_like 'reactive cacheable worker'

  describe '#data_consistency' do
    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(reactive_caching_low_urgency_worker_sticky: true)
      end

      it 'has data_consistency sticky' do
        expect(described_class.get_data_consistency_per_database).to include({ main: :sticky })
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(reactive_caching_low_urgency_worker_sticky: false)
      end

      it 'has data_consistency always' do
        expect(described_class.get_data_consistency_per_database).to include({ main: :always })
      end
    end
  end
end
