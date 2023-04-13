# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Metrics::GlobalMetricsUpdateWorker, feature_category: :metrics do
  subject { described_class.new }

  describe '#perform' do
    let(:service) { ::Metrics::GlobalMetricsUpdateService.new }

    it 'delegates to ::Metrics::GlobalMetricsUpdateService' do
      expect(::Metrics::GlobalMetricsUpdateService).to receive(:new).and_return(service)
      expect(service).to receive(:execute)

      subject.perform
    end

    context 'for an idempotent worker' do
      include_examples 'an idempotent worker' do
        it 'exports metrics' do
          allow(Gitlab).to receive(:maintenance_mode?).and_return(true).at_least(1).time

          perform_multiple

          expect(service.maintenance_mode_metric.get).to eq(1)
        end
      end
    end
  end
end
