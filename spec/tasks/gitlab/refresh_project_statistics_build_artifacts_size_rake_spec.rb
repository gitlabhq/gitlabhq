# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:refresh_project_statistics_build_artifacts_size rake task', :silence_stdout do
  let(:rake_task) { 'gitlab:refresh_project_statistics_build_artifacts_size' }

  describe 'enqueuing build artifacts size statistics refresh for given list of project IDs' do
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_3) { create(:project) }

    let(:string_of_ids) { "#{project_1.id} #{project_2.id} #{project_3.id} 999999" }
    let(:csv_url) { 'https://www.example.com/foo.csv' }
    let(:csv_body) do
      <<~BODY
        PROJECT_ID
        #{project_1.id}
        #{project_2.id}
        #{project_3.id}
      BODY
    end

    before do
      Rake.application.rake_require('tasks/gitlab/refresh_project_statistics_build_artifacts_size')

      stub_const("BUILD_ARTIFACTS_SIZE_REFRESH_ENQUEUE_BATCH_SIZE", 2)

      stub_request(:get, csv_url).to_return(status: 200, body: csv_body)
      allow(Kernel).to receive(:sleep).with(1)
    end

    context 'when given a list of space-separated IDs through rake argument' do
      it 'enqueues the projects for refresh' do
        expect { run_rake_task(rake_task, csv_url) }.to output(/Done/).to_stdout

        expect(Projects::BuildArtifactsSizeRefresh.all.map(&:project)).to match_array([project_1, project_2, project_3])
      end

      it 'inserts refreshes in batches with a sleep' do
        expect(Projects::BuildArtifactsSizeRefresh).to receive(:enqueue_refresh).with(match_array([project_1, project_2])).ordered
        expect(Kernel).to receive(:sleep).with(1)
        expect(Projects::BuildArtifactsSizeRefresh).to receive(:enqueue_refresh).with([project_3]).ordered

        run_rake_task(rake_task, csv_url)
      end
    end

    context 'when CSV has invalid header' do
      let(:csv_body) do
        <<~BODY
          projectid
          #{project_1.id}
          #{project_2.id}
          #{project_3.id}
        BODY
      end

      it 'returns an error message' do
        expect { run_rake_task(rake_task, csv_url) }.to output(/Project IDs must be listed in the CSV under the header PROJECT_ID/).to_stdout
      end
    end
  end
end
