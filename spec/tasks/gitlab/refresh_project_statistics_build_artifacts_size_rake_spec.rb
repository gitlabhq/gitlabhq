# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:refresh_project_statistics_build_artifacts_size rake task', :silence_stdout, feature_category: :job_artifacts do
  let(:rake_task) { 'gitlab:refresh_project_statistics_build_artifacts_size' }

  describe 'enqueuing build artifacts size statistics refresh for given list of project IDs' do
    let!(:project_1) { create(:project) }
    let!(:project_2) { create(:project) }
    let!(:project_3) { create(:project) }

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

      allow(Kernel).to receive(:sleep).with(1)
    end

    shared_examples_for 'recalculates project statistics successfully' do
      it 'enqueues the projects for refresh' do
        expect { run_rake_task(rake_task, csv_path) }.to output(/Done/).to_stdout

        expect(Projects::BuildArtifactsSizeRefresh.all.map(&:project)).to match_array([project_1, project_2, project_3])
      end

      it 'inserts refreshes in batches with a sleep' do
        expect(Projects::BuildArtifactsSizeRefresh).to receive(:enqueue_refresh).with(match_array([project_1, project_2])).ordered
        expect(Kernel).to receive(:sleep).with(1)
        expect(Projects::BuildArtifactsSizeRefresh).to receive(:enqueue_refresh).with([project_3]).ordered

        run_rake_task(rake_task, csv_path)
      end
    end

    shared_examples_for 'raises error for invalid header' do
      let(:csv_body) do
        <<~BODY
          projectid
          #{project_1.id}
          #{project_2.id}
          #{project_3.id}
        BODY
      end

      it 'returns an error message' do
        expect { run_rake_task(rake_task, csv_path) }.to output(/Project IDs must be listed in the CSV under the header PROJECT_ID/).to_stdout
      end
    end

    context 'when given a remote CSV file' do
      let(:csv_path) { 'https://www.example.com/foo.csv' }

      before do
        stub_request(:get, csv_path).to_return(status: 200, body: csv_body)
      end

      it_behaves_like 'recalculates project statistics successfully'
      it_behaves_like 'raises error for invalid header'
    end

    context 'when given a local CSV file' do
      before do
        File.write(csv_path, csv_body, mode: 'w')
      end

      after do
        FileUtils.rm_f(csv_path)
      end

      let(:csv_path) { 'foo.csv' }

      it_behaves_like 'recalculates project statistics successfully'
      it_behaves_like 'raises error for invalid header'
    end
  end
end
