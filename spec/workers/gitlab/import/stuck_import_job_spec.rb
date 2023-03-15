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
end
