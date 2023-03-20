# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::WaitRelationExportsWorker, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project_export_job) { create(:project_export_job, :started) }

  let(:after_export_strategy) { {} }
  let(:job_args) { [project_export_job.id, user.id, after_export_strategy] }

  def create_relation_export(trait, relation, export_error = nil)
    create(:project_relation_export, trait,
      { project_export_job: project_export_job, relation: relation, export_error: export_error }
    )
  end

  before do
    allow_next_instance_of(described_class) do |job|
      allow(job).to receive(:jid) { SecureRandom.hex(8) }
    end
  end

  context 'when export job status is not `started`' do
    it 'does not perform any operation and finishes the worker' do
      finished_export_job = create(:project_export_job, :finished)

      expect { described_class.new.perform(finished_export_job.id, user.id, after_export_strategy) }
        .to change { Projects::ImportExport::ParallelProjectExportWorker.jobs.size }.by(0)
        .and change { described_class.jobs.size }.by(0)
    end
  end

  context 'when there are relation exports with status `queued`' do
    before do
      create_relation_export(:finished, 'labels')
      create_relation_export(:started, 'milestones')
      create_relation_export(:queued, 'merge_requests')
    end

    it 'does not enqueue ParallelProjectExportWorker and re-enqueue WaitRelationExportsWorker' do
      expect { described_class.new.perform(*job_args) }
        .to change { Projects::ImportExport::ParallelProjectExportWorker.jobs.size }.by(0)
        .and change { described_class.jobs.size }.by(1)
    end
  end

  context 'when there are relation exports with status `started`' do
    let(:started_relation_export) { create_relation_export(:started, 'releases') }

    before do
      create_relation_export(:finished, 'labels')
      create_relation_export(:queued, 'merge_requests')
    end

    context 'when the Sidekiq Job exporting the relation is still running' do
      it "does not change relation export's status and re-enqueue WaitRelationExportsWorker" do
        allow(Gitlab::SidekiqStatus).to receive(:running?).with(started_relation_export.jid).and_return(true)

        expect { described_class.new.perform(*job_args) }
          .to change { described_class.jobs.size }.by(1)

        expect(started_relation_export.reload.started?).to eq(true)
      end
    end

    context 'when the Sidekiq Job exporting the relation is still is no longer running' do
      it "set the relation export's status to `failed`" do
        allow(Gitlab::SidekiqStatus).to receive(:running?).with(started_relation_export.jid).and_return(false)

        expect { described_class.new.perform(*job_args) }
          .to change { described_class.jobs.size }.by(1)

        expect(started_relation_export.reload.failed?).to eq(true)
      end
    end
  end

  context 'when all relation exports have status `finished`' do
    before do
      create_relation_export(:finished, 'labels')
      create_relation_export(:finished, 'issues')
    end

    it 'enqueues ParallelProjectExportWorker and does not reenqueue WaitRelationExportsWorker' do
      expect { described_class.new.perform(*job_args) }
        .to change { Projects::ImportExport::ParallelProjectExportWorker.jobs.size }.by(1)
        .and change { described_class.jobs.size }.by(0)
    end

    it_behaves_like 'an idempotent worker'
  end

  context 'when at least one relation export has status `failed` and the rest have status `finished` or `failed`' do
    before do
      create_relation_export(:finished, 'labels')
      create_relation_export(:failed, 'issues', 'Failed to export issues')
      create_relation_export(:failed, 'releases', 'Failed to export releases')
    end

    it_behaves_like 'an idempotent worker' do
      it 'notifies the failed exports to the user' do
        expect_next_instance_of(NotificationService) do |notification_service|
          expect(notification_service).to receive(:project_not_exported)
            .with(
              project_export_job.project,
              user,
              array_including(['Failed to export issues', 'Failed to export releases'])
            )
            .once
        end

        described_class.new.perform(*job_args)
      end
    end

    it 'does not enqueue ParallelProjectExportWorker and re-enqueue WaitRelationExportsWorker' do
      expect { described_class.new.perform(*job_args) }
        .to change { Projects::ImportExport::ParallelProjectExportWorker.jobs.size }.by(0)
        .and change { described_class.jobs.size }.by(0)
    end
  end
end
