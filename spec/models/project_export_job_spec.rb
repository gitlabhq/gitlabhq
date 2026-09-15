# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectExportJob, feature_category: :importers, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:relation_exports) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:jid) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe 'scopes' do
    let_it_be(:current_time) { Time.current }
    let_it_be(:eight_days_ago) { current_time - 8.days }
    let_it_be(:seven_days_ago) { current_time - 7.days }
    let_it_be(:five_days_ago) { current_time - 5.days }

    let_it_be(:user) { create(:user) }

    let_it_be(:recent_export_job) { create(:project_export_job, updated_at: five_days_ago, user: user) }
    let_it_be(:week_old_export_job) { create(:project_export_job, updated_at: seven_days_ago) }
    let_it_be(:prunable_export_job_1) { create(:project_export_job, updated_at: eight_days_ago, user: user) }
    let_it_be(:prunable_export_job_2) { create(:project_export_job, updated_at: eight_days_ago) }

    around do |example|
      travel_to(current_time) { example.run }
    end

    describe '.updated_at_before' do
      it 'only includes records with updated_at older than the given timestamp' do
        expect(described_class.updated_at_before(described_class::EXPIRES_IN.ago))
          .to match_array([prunable_export_job_1, prunable_export_job_2])
      end
    end

    describe '.order_by_updated_at' do
      it 'sorts by updated_at' do
        expect(described_class.order_by_updated_at).to eq(
          [
            prunable_export_job_1,
            prunable_export_job_2,
            week_old_export_job,
            recent_export_job
          ]
        )
      end

      it 'uses id as a tiebreaker' do
        export_jobs_with_same_updated_at = described_class.where(updated_at: eight_days_ago).order_by_updated_at

        expect(export_jobs_with_same_updated_at[0].id).to be < export_jobs_with_same_updated_at[1].id
      end
    end

    describe '.by_user_id' do
      it 'returns export_jobs filtered by user_id' do
        expect(described_class.by_user_id(user.id)).to match_array([recent_export_job, prunable_export_job_1])
      end
    end

    describe '.queued_or_started' do
      let_it_be(:jobs) do
        [
          create(:project_export_job, :queued),
          create(:project_export_job, :started),
          create(:project_export_job, :finished),
          create(:project_export_job, :failed)
        ]
      end

      it 'returns only queued or started jobs' do
        expect(described_class.queued_or_started.pluck(:status)).to all(
          be_in(ProjectExportJob::STATUS.values_at(:queued, :started))
        )
      end
    end

    describe '.started_and_not_timed_out' do
      let_it_be(:fresh_started_job) { create(:project_export_job, :started) }
      let_it_be(:stale_started_job) do
        stale_at = (StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION + 1.minute).ago
        create(:project_export_job, :started, updated_at: stale_at)
      end

      let_it_be(:queued_job) { create(:project_export_job, :queued) }

      it 'returns started jobs updated within the expiration window' do
        expect(described_class.started_and_not_timed_out).to contain_exactly(fresh_started_job)
      end
    end

    describe '.queued_and_not_timed_out' do
      let_it_be(:fresh_queued_job) { create(:project_export_job, :queued) }
      let_it_be(:stale_queued_job) { create(:project_export_job, :queued, updated_at: 31.minutes.ago) }
      let_it_be(:started_job) { create(:project_export_job, :started) }

      it 'returns queued jobs updated within the given timeout' do
        expect(described_class.queued_and_not_timed_out(30.minutes)).to contain_exactly(fresh_queued_job)
      end
    end
  end

  describe '#next_in_queue?' do
    let_it_be(:project) { create(:project) }

    let(:timeout) { 30.minutes }
    let(:current_time) { Time.current }

    around do |example|
      travel_to(current_time) { example.run }
    end

    context 'when available_capacity is exactly at the boundary' do
      let!(:started_job) { create(:project_export_job, :started, project: project) }
      let!(:queued_job) { create(:project_export_job, :queued, project: project) }

      it 'returns false when the limit is already fully occupied' do
        expect(queued_job.next_in_queue?(limit: 1, timeout: timeout)).to be(false)
      end

      it 'returns true when a slot is available' do
        expect(queued_job.next_in_queue?(limit: 2, timeout: timeout)).to be(true)
      end
    end

    context 'when several queued jobs share the same updated_at' do
      let!(:queued_jobs) do
        Array.new(3) { create(:project_export_job, :queued, project: project, updated_at: current_time) }
      end

      it 'breaks the tie by id, admitting only the oldest ids up to the available capacity' do
        oldest_two = queued_jobs.sort_by(&:id).first(2)

        expect(queued_jobs.map { |job| job.next_in_queue?(limit: 2, timeout: timeout) }).to eq(
          queued_jobs.map { |job| oldest_two.include?(job) }
        )
      end
    end

    context 'when a queued job is past its timeout' do
      let!(:timed_out_job) do
        create(:project_export_job, :queued, project: project, updated_at: (timeout + 1.minute).ago)
      end

      let!(:fresh_job) { create(:project_export_job, :queued, project: project) }

      it 'excludes the timed-out job from the ordering pool instead of ranking it last' do
        expect(timed_out_job.next_in_queue?(limit: 1, timeout: timeout)).to be(false)
        expect(fresh_job.next_in_queue?(limit: 1, timeout: timeout)).to be(true)
      end
    end

    context 'when the started and queued timeouts expire independently' do
      let!(:timed_out_started_job) do
        stale_at = (StuckExportJobsWorker::EXPORT_JOBS_EXPIRATION + 1.minute).ago
        create(:project_export_job, :started, project: project, updated_at: stale_at)
      end

      let!(:timed_out_queued_job) do
        create(:project_export_job, :queued, project: project, updated_at: (timeout + 1.minute).ago)
      end

      let!(:fresh_queued_job) { create(:project_export_job, :queued, project: project) }

      it 'does not let the queued timeout affect the started scope, or vice versa' do
        expect(described_class.started_and_not_timed_out).to be_empty
        expect(described_class.queued_and_not_timed_out(timeout)).to contain_exactly(fresh_queued_job)

        expect(fresh_queued_job.next_in_queue?(limit: 1, timeout: timeout)).to be(true)
      end
    end
  end

  describe 'status transitions' do
    let(:queued)   { ProjectExportJob::STATUS[:queued] }
    let(:started)  { ProjectExportJob::STATUS[:started] }
    let(:failed)   { ProjectExportJob::STATUS[:failed] }
    let(:finished) { ProjectExportJob::STATUS[:finished] }

    context 'when a new ProjectExportJob is created' do
      let(:project_export_job) { create(:project_export_job) }

      it 'is initialized in the queued state' do
        expect(project_export_job).to be_queued
      end
    end

    context 'when the ProjectExportJob is in queued state' do
      let(:project_export_job) { create(:project_export_job) }

      it 'can transition to started state' do
        expect { project_export_job.start }.to change { project_export_job.status }.from(queued).to(started)
      end

      it 'can transition to failed state' do
        expect { project_export_job.fail_op }.to change { project_export_job.status }.from(queued).to(failed)
      end

      it 'cannnot transition to finished state' do
        expect { project_export_job.finish }.not_to change { project_export_job.status }
      end
    end

    context 'when the ProjectExportJob is in started state' do
      let(:project_export_job) { create(:project_export_job, status: started) }

      it 'can transition to finished state' do
        expect { project_export_job.finish }.to change { project_export_job.status }.from(started).to(finished)
      end

      it 'can transition to failed state' do
        expect { project_export_job.fail_op }.to change { project_export_job.status }.from(started).to(failed)
      end
    end

    context 'when the ProjectExportJob is in finished state' do
      let(:project_export_job) { create(:project_export_job, status: finished) }

      it 'does not transition further' do
        expect { project_export_job.fail_op }.not_to change { project_export_job.status }
      end
    end
  end

  describe '#finish' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let(:export_job) { build(:project_export_job, :started, user: user, project: project) }

    let(:expected_audit) do
      {
        name: 'project_export_created',
        author: user,
        scope: project,
        target: project,
        message: 'Profile file export was created'
      }
    end

    subject(:finish) { export_job.finish }

    it 'creates an audit event' do
      expect(Gitlab::Audit::Auditor).to receive(:audit).with(expected_audit)

      finish
    end

    context 'when user is nil' do
      let_it_be(:user) { nil }

      it 'creates an audit event' do
        expect(Gitlab::Audit::Auditor).to receive(:audit).with(expected_audit)

        finish
      end
    end

    context 'when user was admin', :enable_admin_mode do
      let_it_be(:user) { create(:admin) }

      it 'creates an audit event' do
        expect(Gitlab::Audit::Auditor).to receive(:audit).with(expected_audit)

        finish
      end

      context 'when silent exports enabled' do
        before do
          stub_application_setting(silent_admin_exports_enabled: true)
        end

        it 'does not create an audit event' do
          expect(Gitlab::Audit::Auditor).not_to receive(:audit)

          finish
        end
      end
    end
  end
end
