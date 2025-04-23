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
        expect(restorer).to receive(:restore_single_relation).with(tracker.relation,
          extra_track_scope: { tracker_id: tracker.id })
      end

      perform
    end

    it 'marks the tracker as finished' do
      expect { perform }.to change { tracker.reload.finished? }.from(false).to(true)
    end

    it 'refreshes the project stats' do
      allow(worker).to receive(:project).and_return(tracker.project)
      expect(tracker.project).to receive(:reset_counters_and_iids)
      expect(InternalId).to receive(:flush_records!).with(namespace: tracker.project.project_namespace)

      perform
    end

    it 'does not change any project attributes' do
      tracker.project.update!(description: 'an updated description', approvals_before_merge: 2, visibility_level: 10)

      expect { perform }.not_to change { tracker.project.reload.attributes }
    end
  end

  context 'when the import fails' do
    before do
      allow(worker).to receive(:process_import).and_raise(StandardError, 'import_forced_to_fail')
    end

    it 'creates a record of the failure' do
      expect { perform }
        .to raise_error(StandardError, 'import_forced_to_fail')
        .and change { tracker.reload.project.import_failures.count }.by(1)

      failure = tracker.project.import_failures.last
      expect(failure.exception_message).to eq('import_forced_to_fail')
    end
  end

  context 'when tracker can not be started' do
    before do
      tracker.update!(status: 2)
    end

    it 'does not start the import process' do
      expect(Import::Framework::Logger).to receive(:info).with(message: 'Cannot start tracker', tracker_id: tracker.id,
        tracker_status: :finished)

      perform
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

  describe '.sidekiq_retries_exhausted' do
    it 'marks the tracker as failed and creates a record of the failure' do
      job = { 'args' => [tracker.id, user.id] }

      expect { described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new('Error!')) }.to change {
        tracker.reload.failed?
      }.from(false).to(true)

      failure = tracker.project.import_failures.last
      expect(failure.exception_message).to eq('Error!')
    end
  end

  describe '.sidekiq_interruptions_exhausted' do
    it 'marks the tracker as failed and creates a record of the failure' do
      job = { 'args' => [tracker.id, user.id] }

      expect { described_class.interruptions_exhausted_block.call(job) }.to change {
        tracker.reload.failed?
      }.from(false).to(true)

      failure = tracker.project.import_failures.last
      expect(failure.exception_message).to eq('Import process reached the maximum number of interruptions')
    end
  end
end
