# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Lfs, feature_category: :source_code_management do
  describe '#initialize_slis!' do
    it 'initializes all metrics' do
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(:lfs_update_objects, [{}])
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(:lfs_check_objects, [{}])
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(:lfs_validate_link_objects, [{}])

      described_class.initialize_slis!
    end
  end

  describe '#update_objects_error_rate' do
    it 'calls increment on lfs_update_objects metric' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:lfs_update_objects]).to receive(:increment).once

      described_class.update_objects_error_rate.increment(error: true, labels: {})
    end
  end

  describe '#check_objects_error_rate' do
    it 'calls increment on lfs_check_objects metric' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:lfs_check_objects]).to receive(:increment).once

      described_class.check_objects_error_rate.increment(error: true, labels: {})
    end
  end

  describe '#validate_link_objects_error_rate' do
    it 'calls increment on lfs_validate_link_objects metric' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:lfs_validate_link_objects]).to receive(:increment).once

      described_class.validate_link_objects_error_rate.increment(error: true, labels: {})
    end
  end
end
