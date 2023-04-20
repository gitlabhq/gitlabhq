# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::GlobalMetricsUpdateService, :prometheus, feature_category: :metrics do
  describe '#execute' do
    it 'sets gitlab_maintenance_mode gauge metric' do
      metric = subject.maintenance_mode_metric
      expect(Gitlab).to receive(:maintenance_mode?).and_return(true)

      expect { subject.execute }.to change { metric.get }.from(0).to(1)
    end
  end
end
