# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectImportOptions, feature_category: :importers do
  let(:project) { create(:project, :import_started) }
  let(:job) { { 'args' => [project.id, nil, nil], 'jid' => '123' } }
  let(:worker_class) do
    Class.new do
      include Sidekiq::Worker
      include ProjectImportOptions
    end
  end

  it 'sets default retry limit' do
    expect(worker_class.sidekiq_options['retry']).to eq(ProjectImportOptions::IMPORT_RETRY_COUNT)
  end

  it 'sets default status expiration' do
    expect(worker_class.sidekiq_options['status_expiration']).to eq(Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION)
  end

  describe '.sidekiq_retries_exhausted' do
    it 'marks fork as failed' do
      expect { worker_class.sidekiq_retries_exhausted_block.call(job) }.to change { project.reload.import_status }.from("started").to("failed")
    end

    it 'logs the appropriate error message for forked projects' do
      allow_any_instance_of(Project).to receive(:forked?).and_return(true)

      worker_class.sidekiq_retries_exhausted_block.call(job)

      expect(project.import_state.reload.last_error).to include("fork")
    end

    it 'logs the appropriate error message for forked projects' do
      worker_class.sidekiq_retries_exhausted_block.call(job)

      expect(project.import_state.reload.last_error).to include("import")
    end

    context 'when project is jira import' do
      let(:project) { create(:project, import_type: 'jira') }
      let!(:jira_import) { create(:jira_import_state, project: project) }

      it 'logs the appropriate error message for forked projects' do
        worker_class.sidekiq_retries_exhausted_block.call(job)

        expect(project.latest_jira_import.reload.status).to eq('failed')
      end
    end

    context 'when project does not have import_state' do
      let(:project) { create(:project) }

      it 'raises an error' do
        expect do
          worker_class.sidekiq_retries_exhausted_block.call(job)
        end.to raise_error(NoMethodError)
      end
    end
  end
end
