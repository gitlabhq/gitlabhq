# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProjectDailyStatisticsWorker, '#perform' do
  let(:worker) { described_class.new }
  let(:project) { create(:project) }

  describe '#perform' do
    context 'with a non-existing project' do
      it 'does nothing' do
        expect(Projects::FetchStatisticsIncrementService).not_to receive(:new)

        worker.perform(-1)
      end
    end

    context 'with an existing project without a repository' do
      it 'does nothing' do
        expect(Projects::FetchStatisticsIncrementService).not_to receive(:new)

        worker.perform(project.id)
      end
    end

    it 'calls daily_statistics_service with the given project' do
      project = create(:project, :repository)

      expect_next_instance_of(Projects::FetchStatisticsIncrementService, project) do |service|
        expect(service).to receive(:execute)
      end

      worker.perform(project.id)
    end
  end
end
