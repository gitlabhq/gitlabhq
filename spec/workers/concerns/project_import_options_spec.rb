require 'spec_helper'

describe ProjectImportOptions do
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
    expect(worker_class.sidekiq_options['status_expiration']).to eq(StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION)
  end

  describe '.sidekiq_retries_exhausted' do
    it 'marks fork as failed' do
      expect { worker_class.sidekiq_retries_exhausted_block.call(job) }.to change { project.reload.import_status }.from("started").to("failed")
    end

    it 'logs the appropriate error message for forked projects' do
      allow_any_instance_of(Project).to receive(:forked?).and_return(true)

      worker_class.sidekiq_retries_exhausted_block.call(job)

      expect(project.reload.import_error).to include("fork")
    end

    it 'logs the appropriate error message for forked projects' do
      worker_class.sidekiq_retries_exhausted_block.call(job)

      expect(project.reload.import_error).to include("import")
    end
  end
end
