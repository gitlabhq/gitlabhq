# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ScheduleRefreshBuildArtifactsSizeStatisticsWorker, feature_category: :job_artifacts do
  subject(:worker) { described_class.new }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      it 'schedules Projects::RefreshBuildArtifactsSizeStatisticsWorker to be performed with capacity' do
        expect(Projects::RefreshBuildArtifactsSizeStatisticsWorker).to receive(:perform_with_capacity).twice

        subject
      end
    end
  end
end
