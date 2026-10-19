# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::CreateRelationExportsWorker, feature_category: :importers do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:after_export_strategy) { {} }
  let(:params) { {} }
  let(:jid) { SecureRandom.hex(8) }
  let(:job_args) { [user.id, project.id, after_export_strategy, params] }
  let(:extra_key_prefix) { 'extra.projects_import_export_create_relation_exports_worker' }

  before do
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(200)

    allow_next_instance_of(described_class) do |job|
      allow(job).to receive(:jid).and_return(jid)
    end
  end

  it_behaves_like 'an idempotent worker'

  subject(:perform) { described_class.new.perform(user.id, project.id, after_export_strategy, params) }

  context 'when a ProjectExportJob already exists for this user and project' do
    it_behaves_like 'an idempotent worker'

    it 'does not start the export process twice' do
      project.export_jobs.create!(jid: SecureRandom.hex(8), user_id: user.id, status_event: :start)

      expect { perform }.not_to change { Projects::ImportExport::WaitRelationExportsWorker.jobs.size }
    end
  end

  it 'creates a export_job and sets the status to `started`' do
    perform

    export_job = project.export_jobs.last
    expect(export_job.started?).to be(true)
  end

  it 'creates relation export records and enqueues a worker for each relation to be exported' do
    allow(Projects::ImportExport::RelationExport).to receive(:relation_names_list).and_return(%w[relation_1 relation_2])

    expect { perform }.to change { Projects::ImportExport::RelationExportWorker.jobs.size }.by(2)

    relation_exports = project.export_jobs.last.relation_exports
    expect(relation_exports.collect(&:relation)).to match_array(%w[relation_1 relation_2])
  end

  it 'enqueues a WaitRelationExportsWorker' do
    allow(Projects::ImportExport::WaitRelationExportsWorker).to receive(:perform_in)

    perform

    export_job = project.export_jobs.last
    expect(Projects::ImportExport::WaitRelationExportsWorker).to have_received(:perform_in).with(
      described_class::INITIAL_DELAY,
      export_job.id,
      user.id,
      after_export_strategy
    )
  end

  it 'creates a ProjectExportJob in the correct state' do
    expect { perform }.to change { ProjectExportJob.count }.by(1)

    expect(project.export_jobs).to contain_exactly(
      have_attributes(
        user: user,
        exported_by_admin: false,
        jid: jid,
        status: 1
      )
    )
  end

  context 'when user was an admin' do
    let(:params) { { exported_by_admin: true } }

    it 'creates a ProjectExportJob in correct state' do
      perform

      expect(project.export_jobs).to contain_exactly(
        have_attributes(
          user: user,
          exported_by_admin: true
        )
      )
    end

    it 'passes the params on as native JSON types' do
      allow(Projects::ImportExport::RelationExport).to receive(:relation_names_list).and_return(%w[relation_1])

      perform

      enqueued_params = Projects::ImportExport::RelationExportWorker.jobs.map { |job| job['args'].last }
      expect(enqueued_params).to param_containing_valid_native_json_types
      expect(enqueued_params).to contain_exactly({ 'exported_by_admin' => true })
    end
  end

  context 'with excluded_relations' do
    let(:excluded_relations) { %w[uploads lfs_objects] }
    let(:params) { { 'excluded_relations' => excluded_relations } }
    let(:all_relation_names) { Projects::ImportExport::RelationExport.relation_names_list }

    let(:export_job) { project.export_jobs.last }

    it_behaves_like 'an idempotent worker'

    it 'does not create relation exports for the excluded relations' do
      perform

      expect(export_job.relation_exports.by_relation(excluded_relations)).to be_empty
    end

    it 'creates a relation export for every other relation' do
      perform

      expect(export_job.relation_exports.pluck(:relation)).to match_array(all_relation_names - excluded_relations)
    end

    it 'enqueues a RelationExportWorker for every other relation and none for the excluded ones' do
      perform

      enqueued_relation_export_ids = Projects::ImportExport::RelationExportWorker.jobs.map { |job| job['args'].first }

      expect(enqueued_relation_export_ids).to match_array(export_job.relation_exports.ids)
      expect(enqueued_relation_export_ids.size).to eq(all_relation_names.size - excluded_relations.size)
    end

    it 'passes the params on as native JSON types' do
      perform

      enqueued_params = Projects::ImportExport::RelationExportWorker.jobs.map { |job| job['args'].last }

      expect(enqueued_params).to param_containing_valid_native_json_types
      expect(enqueued_params).to all(eq(params))
    end

    it 'starts the export and enqueues a WaitRelationExportsWorker' do
      expect { perform }.to change { Projects::ImportExport::WaitRelationExportsWorker.jobs.size }.by(1)

      expect(export_job.started?).to be(true)
    end

    context 'when the params have symbol keys' do
      let(:params) { { excluded_relations: excluded_relations } }

      it 'does not create relation exports for the excluded relations' do
        perform

        expect(export_job.relation_exports.by_relation(excluded_relations)).to be_empty
      end
    end

    context 'when the excluded relations include relations that must not be excluded' do
      let(:excluded_relations) { %w[project repository uploads] }

      it 'only skips the relations that can be excluded' do
        perform

        expect(export_job.relation_exports.pluck(:relation)).to match_array(all_relation_names - %w[uploads])
      end
    end
  end

  describe 'sidekiq deduplication configuration' do
    it 'reschedules deduplicated jobs so a self re-enqueue is not dropped' do
      expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
      expect(described_class.get_deduplication_options).to include(if_deduplicated: :reschedule_once)
    end
  end

  describe 'concurrency and FIFO gate' do
    describe 'effective concurrency limit' do
      using RSpec::Parameterized::TableSyntax

      where(:com, :expected_limit) do
        true  | 250
        false | 10
      end

      with_them do
        before do
          stub_application_setting(concurrent_relation_export_limit: 10)
          allow(Gitlab).to receive(:com?).and_return(com)
        end

        it 'gates and logs with the effective limit' do
          expect_next_instance_of(ProjectExportJob) do |export_job|
            expect(export_job).to receive(:next_in_queue?)
              .with(limit: expected_limit, timeout: described_class::QUEUED_JOBS_EXPIRATION)
              .and_call_original
          end

          worker = described_class.new
          worker.perform(*job_args)

          expect(worker.logging_extras).to include(
            "#{extra_key_prefix}.concurrent_relation_export_limit" => expected_limit
          )
        end
      end
    end

    context 'when under the concurrency limit' do
      before do
        stub_application_setting(concurrent_relation_export_limit: 5)
      end

      it 'starts the export immediately' do
        perform

        expect(project.export_jobs.last.started?).to be(true)
      end

      it 'logs how long the export was queued and the limit in force' do
        create(:project_export_job, :queued, project: project, user: user, created_at: 10.minutes.ago)
        worker = described_class.new

        worker.perform(*job_args)

        expect(worker.logging_extras).to include(
          "#{extra_key_prefix}.concurrent_relation_export_limit" => 5,
          "#{extra_key_prefix}.queued_duration_s" => be_within(5).of(10.minutes.to_i)
        )
      end
    end

    context 'when the concurrency limit has already been reached' do
      let_it_be_with_reload(:other_started_job) { create(:project_export_job, :started) }

      before do
        stub_application_setting(concurrent_relation_export_limit: 1)
      end

      it 'does not start the export and re-enqueues itself' do
        expect(described_class).to receive(:perform_in)
          .with(described_class::RE_ENQUEUE_DELAY, user.id, project.id, after_export_strategy, params)
          .and_call_original

        expect { perform }.not_to change { Projects::ImportExport::RelationExportWorker.jobs.size }

        export_job = project.export_jobs.last
        expect(export_job.queued?).to be(true)
      end

      it 'does not log a queued duration' do
        worker = described_class.new

        worker.perform(*job_args)

        expect(worker.logging_extras).to include("#{extra_key_prefix}.re_enqueue" => true)
        expect(worker.logging_extras).not_to have_key("#{extra_key_prefix}.queued_duration_s")
      end

      it 'logs the queue size and configured limit alongside the re-enqueue' do
        expect(Gitlab::Export::Logger).to receive(:info).with(
          hash_including(
            message: 'Throttled project export was re-enqueued',
            Labkit::Fields::GL_PROJECT_ID => project.id,
            queue_size: 1,
            concurrent_relation_export_limit: 1
          )
        )

        perform
      end

      it "updates its jid to the re-enqueued job's, so StuckExportJobsWorker sees it as still alive" do
        perform

        export_job = project.export_jobs.last
        re_enqueued_job = described_class.jobs.last

        expect(re_enqueued_job['args']).to eq([user.id, project.id, after_export_strategy, params])
        expect(export_job.jid).to eq(re_enqueued_job['jid'])
      end

      it 'reuses the same queued ProjectExportJob on a later attempt, regardless of jid' do
        perform
        export_job = project.export_jobs.last

        allow_next_instance_of(described_class) do |job|
          allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
        end

        expect do
          described_class.new.perform(user.id, project.id, after_export_strategy, params)
        end.not_to change { ProjectExportJob.count }

        expect(export_job.reload.queued?).to be(true)
      end

      context 'with excluded_relations' do
        let(:excluded_relations) { %w[uploads lfs_objects] }
        let(:params) { { 'excluded_relations' => excluded_relations } }

        it 're-enqueues itself with the excluded relations' do
          perform

          expect(described_class.jobs.last['args']).to eq([user.id, project.id, after_export_strategy, params])
        end

        it 'skips the excluded relations when the re-enqueued job starts the export' do
          perform
          other_started_job.finish!

          described_class.new.perform(*described_class.jobs.last['args'])

          relation_names = project.export_jobs.last.relation_exports.pluck(:relation)

          expect(relation_names).not_to include(*excluded_relations)
          expect(relation_names).to match_array(
            Projects::ImportExport::RelationExport.relation_names_list - excluded_relations
          )
        end
      end

      context 'and the started job has timed out' do
        before do
          other_started_job.update!(updated_at: (StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION + 1.minute).ago)
        end

        it 'no longer counts it towards the limit and starts the export' do
          perform

          expect(project.export_jobs.last.started?).to be(true)
        end
      end

      context 'and the job cannot be re-enqueued' do
        before do
          allow(described_class).to receive(:perform_in).and_return(nil)
        end

        it 'logs the abandoned export and leaves it queued' do
          expect(Gitlab::Export::Logger).to receive(:error).with(
            hash_including(
              message: 'Throttled project export was not re-enqueued',
              Labkit::Fields::GL_PROJECT_ID => project.id
            )
          )

          perform

          export_job = project.export_jobs.last
          expect(export_job.queued?).to be(true)
          expect(export_job.jid).to eq(jid)
        end

        it 'does not log a successful re-enqueue' do
          expect(Gitlab::Export::Logger).not_to receive(:info).with(
            hash_including(message: 'Throttled project export was re-enqueued')
          )

          perform
        end
      end
    end

    context 'when the limit_concurrent_project_exports feature flag is disabled' do
      let_it_be(:other_started_job) { create(:project_export_job, :started) }

      before do
        stub_feature_flags(limit_concurrent_project_exports: false)
        stub_application_setting(concurrent_relation_export_limit: 1)
      end

      it 'starts the export regardless of the limit' do
        expect(described_class).not_to receive(:perform_in)
          .with(described_class::RE_ENQUEUE_DELAY, any_args)

        perform

        expect(project.export_jobs.last.started?).to be(true)
      end

      it 'does not log the queued duration or the limit' do
        worker = described_class.new

        worker.perform(*job_args)

        expect(worker.logging_extras.keys).not_to include(
          "#{extra_key_prefix}.queued_duration_s",
          "#{extra_key_prefix}.concurrent_relation_export_limit"
        )
      end

      it 'looks the export job up by jid' do
        export_job = project.export_jobs.create!(jid: jid, user_id: user.id)

        expect { perform }.not_to change { ProjectExportJob.count }
        expect(export_job.reload.started?).to be(true)
      end
    end

    context 'when multiple exports are queued' do
      let_it_be(:project_2) { create(:project) }
      let_it_be(:project_3) { create(:project) }

      let_it_be(:oldest_job) { create(:project_export_job, :queued, project: project, user: user) }
      let_it_be(:middle_job) { create(:project_export_job, :queued, project: project_2, user: user) }
      let_it_be(:newest_job) { create(:project_export_job, :queued, project: project_3, user: user) }

      before do
        stub_application_setting(concurrent_relation_export_limit: 1)
      end

      def perform_for(project)
        described_class.new.perform(user.id, project.id, {}, {})
      end

      it 'promotes the oldest queued job first, not whichever job is asked about first' do
        perform_for(project_3)
        expect(newest_job.reload.queued?).to be(true)

        perform_for(project)
        expect(oldest_job.reload.started?).to be(true)

        perform_for(project_2)
        expect(middle_job.reload.queued?).to be(true)
      end

      context 'and the oldest queued jobs have stopped being re-enqueued' do
        before do
          [oldest_job, middle_job].each do |export_job|
            export_job.update!(updated_at: (described_class::QUEUED_JOBS_EXPIRATION + 1.minute).ago)
          end
        end

        it 'ignores them so they do not hold the queue positions' do
          perform_for(project_3)

          expect(newest_job.reload.started?).to be(true)
        end
      end
    end
  end
end
