# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::ScheduleAnnotationsPruneWorker do
  describe '#perform' do
    it 'schedules annotations prune job with default cut off date' do
      expect(Metrics::Dashboard::PruneOldAnnotationsWorker).to receive(:perform_async)

      described_class.new.perform
    end
  end
end
