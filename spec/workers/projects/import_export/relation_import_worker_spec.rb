# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RelationImportWorker, feature_category: :importers do
  let_it_be_with_reload(:tracker) { create(:relation_import_tracker, status: 'created') }

  let_it_be(:user) { create(:user) }
  let(:worker) { described_class.new }

  subject(:perform) { worker.perform(tracker.id, user.id) }

  before do
    create(
      :import_export_upload,
      import_file: fixture_file_upload('spec/features/projects/import_export/test_project_export.tar.gz'),
      project: tracker.project,
      user: user
    )
  end

  context 'when the import succeeds' do
    it 'schedules the relation restoration' do
      expect_next_instance_of(Gitlab::ImportExport::Project::RelationTreeRestorer) do |restorer|
        expect(restorer).to receive(:restore_single_relation).with(tracker.relation)
      end

      perform
    end

    it 'marks the tracker as finished' do
      expect { perform }.to change { tracker.reload.finished? }.from(false).to(true)
    end

    it 'refreshes the project stats' do
      expect(worker).to receive(:perform_post_import_tasks)

      perform
    end
  end

  context 'when the import fails' do
    before do
      allow(worker).to receive(:process_import).and_raise(StandardError, 'import_forced_to_fail')
    end

    it 'marks the tracker as failed' do
      expect { perform }
        .to raise_error(StandardError, 'import_forced_to_fail')
        .and change { tracker.reload.failed? }.from(false).to(true)
    end

    it 'creates a record of the failure' do
      expect { perform }
        .to raise_error(StandardError, 'import_forced_to_fail')
        .and change { tracker.reload.project.import_failures.count }.by(1)

      failure = tracker.project.import_failures.last
      expect(failure.exception_message).to eq('import_forced_to_fail')
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [tracker.id, user.id] }

    it 'only starts one import when triggered multiple times' do
      perform_multiple(job_args)

      expect(tracker.reload.finished?).to be_truthy
    end

    it 'does not log any error when triggered multiple times' do
      expect { perform_multiple(job_args) }.not_to change { tracker.reload.project.import_failures.count }
    end
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed
end
