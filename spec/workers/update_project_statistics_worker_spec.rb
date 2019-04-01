require 'spec_helper'

describe UpdateProjectStatisticsWorker do
  let(:worker) { described_class.new }
  let(:project) { create(:project, :repository) }

  describe '#perform' do
    context 'with a non-existing project' do
      it 'does nothing' do
        expect_any_instance_of(ProjectStatistics).not_to receive(:refresh!)

        worker.perform(-1)
      end
    end

    context 'with an existing project without a repository' do
      it 'does nothing' do
        allow_any_instance_of(Repository).to receive(:exists?).and_return(false)

        expect_any_instance_of(ProjectStatistics).not_to receive(:refresh!)

        worker.perform(project.id)
      end
    end

    context 'with an existing project' do
      it 'refreshes the project statistics' do
        expect_any_instance_of(ProjectStatistics).to receive(:refresh!)
          .with(only: [])
          .and_call_original

        worker.perform(project.id)
      end

      context 'with a specific statistics target' do
        it 'refreshes the project repository size' do
          statistics_target = %w(repository_size)

          expect_any_instance_of(ProjectStatistics).to receive(:refresh!)
            .with(only: statistics_target.map(&:to_sym))
            .and_call_original

          worker.perform(project.id, statistics_target)
        end
      end
    end
  end
end
