# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:refresh_project_statistics_build_artifacts_size rake task', :silence_stdout do
  let(:rake_task) { 'gitlab:refresh_project_statistics_build_artifacts_size' }

  describe 'enqueuing build artifacts size statistics refresh for given list of project IDs' do
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_3) { create(:project) }

    let(:string_of_ids) { "#{project_1.id} #{project_2.id} #{project_3.id} 999999" }

    before do
      Rake.application.rake_require('tasks/gitlab/refresh_project_statistics_build_artifacts_size')

      stub_const("BUILD_ARTIFACTS_SIZE_REFRESH_ENQUEUE_BATCH_SIZE", 2)
    end

    context 'when given a list of space-separated IDs through STDIN' do
      before do
        allow($stdin).to receive(:tty?).and_return(false)
        allow($stdin).to receive(:read).and_return(string_of_ids)
      end

      it 'enqueues the projects for refresh' do
        expect { run_rake_task(rake_task) }.to output(/Done/).to_stdout

        expect(Projects::BuildArtifactsSizeRefresh.all.map(&:project)).to match_array([project_1, project_2, project_3])
      end
    end

    context 'when given a list of space-separated IDs through rake argument' do
      it 'enqueues the projects for refresh' do
        expect { run_rake_task(rake_task, string_of_ids) }.to output(/Done/).to_stdout

        expect(Projects::BuildArtifactsSizeRefresh.all.map(&:project)).to match_array([project_1, project_2, project_3])
      end
    end

    context 'when not given any IDs' do
      it 'returns an error message' do
        expect { run_rake_task(rake_task) }.to output(/Please provide a string of space-separated project IDs/).to_stdout
      end
    end
  end
end
