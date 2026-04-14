# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::StuckImportJob, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started, import_source: 'foo/bar') }

  let(:worker) do
    Class.new do
      def self.name
        'MyStuckProjectImportsWorker'
      end

      include(Gitlab::Import::StuckImportJob)

      def track_metrics(...)
        nil
      end

      def enqueued_import_states
        ProjectImportState.with_status([:scheduled, :started])
      end
    end.new
  end

  it 'marks the stuck import project as failed and track the error on import_failures' do
    worker.perform

    expect(project.import_state.reload.status).to eq('failed')
    expect(project.import_state.last_error).to eq('Import timed out. Import took longer than 86400 seconds')

    expect(project.import_failures).not_to be_empty
    expect(project.import_failures.last.exception_class).to eq('Gitlab::Import::StuckImportJob::StuckImportJobError')
    expect(project.import_failures.last.exception_message).to eq('Import timed out. Import took longer than 86400 seconds')
  end

  describe 'failure tracking' do
    it 'calls ImportFailureService with the correct arguments' do
      create(:project, :import_started, import_source: 'foo/bar').tap do |p|
        p.import_state.update!(jid: 'abc123')
      end

      allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return(['abc123'])
      allow(Gitlab::Import::ImportFailureService).to receive(:track).and_call_original

      expect(Gitlab::Import::ImportFailureService).to receive(:track).with(
        hash_including(
          message: 'Marking stuck import job as failed',
          capture_exception: false,
          extra_attributes: { jid: 'abc123', mirror: false }
        )
      )

      worker.perform
    end
  end
end
