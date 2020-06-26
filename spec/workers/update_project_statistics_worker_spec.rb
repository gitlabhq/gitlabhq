# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateProjectStatisticsWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project, :repository) }
  let(:statistics) { %w(repository_size) }

  describe '#perform' do
    it 'updates the project statistics' do
      expect(Projects::UpdateStatisticsService).to receive(:new)
        .with(project, nil, statistics: statistics)
        .and_call_original

      worker.perform(project.id, statistics)
    end
  end
end
