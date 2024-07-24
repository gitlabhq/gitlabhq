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

    describe '.prunable' do
      it 'only includes records with updated_at older than 7 days ago' do
        expect(described_class.prunable).to match_array([prunable_export_job_1, prunable_export_job_2])
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
