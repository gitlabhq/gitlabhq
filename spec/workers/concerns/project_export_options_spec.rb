# frozen_string_literal: true

require 'spec_helper'

describe ProjectExportOptions do
  let(:project) { create(:project) }
  let(:project_export_job) { create(:project_export_job, project: project, jid: '123', status: 1) }
  let(:job) { { 'args' => [project.owner.id, project.id, nil, nil], 'jid' => '123' } }
  let(:worker_class) do
    Class.new do
      include Sidekiq::Worker
      include ProjectExportOptions
    end
  end

  it 'sets default retry limit' do
    expect(worker_class.sidekiq_options['retry']).to eq(ProjectExportOptions::EXPORT_RETRY_COUNT)
  end

  it 'sets default status expiration' do
    expect(worker_class.sidekiq_options['status_expiration']).to eq(StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION)
  end

  describe '.sidekiq_retries_exhausted' do
    it 'marks status as failed' do
      expect { worker_class.sidekiq_retries_exhausted_block.call(job) }.to change { project_export_job.reload.status }.from(1).to(3)
    end

    context 'when status update fails' do
      before do
        project_export_job.update(status: 2)
      end

      it 'logs an error' do
        expect(Sidekiq.logger).to receive(:error).with("Failed to set Job #{job['jid']} for project #{project.id} to failed state")

        worker_class.sidekiq_retries_exhausted_block.call(job)
      end
    end
  end
end
