# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineScheduleOwnershipValidator, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  describe '#pipeline_schedule_ownership_revoked?' do
    let_it_be_with_reload(:member) do
      create(:project_member, source: project, user: user, access_level: Member::DEVELOPER)
    end

    context 'when access level has not changed' do
      it 'returns false' do
        expect(member.pipeline_schedule_ownership_revoked?).to be false
      end
    end

    context 'when access level changed to level >= DEVELOPER' do
      it 'returns false when upgraded from REPORTER to DEVELOPER' do
        member.update!(access_level: Member::REPORTER)
        member.update!(access_level: Member::DEVELOPER)

        expect(member.pipeline_schedule_ownership_revoked?).to be false
      end

      it 'returns false when upgraded from DEVELOPER to MAINTAINER' do
        # member starts as developer (from let_it_be_with_reload)
        member.update!(access_level: Member::MAINTAINER)

        expect(member.pipeline_schedule_ownership_revoked?).to be false
      end

      it 'returns false when downgraded from MAINTAINER to DEVELOPER' do
        member.update!(access_level: Member::MAINTAINER)
        member.update!(access_level: Member::DEVELOPER)

        expect(member.pipeline_schedule_ownership_revoked?).to be false
      end
    end

    context 'when access level chanved to level < DEVELOPER' do
      # member instance starts as developer (from let_it_be_with_reload)

      it 'returns true when downgraded from DEVELOPER to REPORTER' do
        member.update!(access_level: Member::REPORTER)

        expect(member.pipeline_schedule_ownership_revoked?).to be true
      end

      it 'returns true when downgraded from MAINTAINER to REPORTER' do
        member.update!(access_level: Member::MAINTAINER)
        member.update!(access_level: Member::REPORTER)

        expect(member.pipeline_schedule_ownership_revoked?).to be true
      end

      it 'returns true when downgraded from OWNER to GUEST' do
        member.update!(access_level: Member::OWNER)
        member.update!(access_level: Member::GUEST)

        expect(member.pipeline_schedule_ownership_revoked?).to be true
      end

      it 'returns true when downgraded from DEVELOPER to GUEST' do
        member.update!(access_level: Member::GUEST)

        expect(member.pipeline_schedule_ownership_revoked?).to be true
      end

      it 'returns false when changed from non-developer to non-developer' do
        member.update!(access_level: Member::GUEST)
        member.update!(access_level: Member::REPORTER)

        expect(member.pipeline_schedule_ownership_revoked?).to be false
      end
    end
  end

  describe '#notify_unavailable_owned_pipeline_schedules' do
    let_it_be(:reporter_member) { create(:project_member, source: project, user: user, access_level: Member::REPORTER) }

    context 'with active owned pipeline_schedules' do
      let(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project, owner: reporter_member.user) }

      it 'sends owner unavailable email and deactivates the schedule' do
        expect(NotificationService).to receive_message_chain(:new,
          :pipeline_schedule_owner_unavailable).with(pipeline_schedule)

        reporter_member.notify_unavailable_owned_pipeline_schedules(reporter_member.user.id, reporter_member.source)
        expect(pipeline_schedule.reload.active).to be false
      end
    end

    context 'with inactive owned pipeline_schedules' do
      before do
        create(:ci_pipeline_schedule, :nightly, project: project, owner: reporter_member.user, active: false)
      end

      it 'does not send owner unavailable email' do
        expect(NotificationService).not_to receive(:new)

        reporter_member.notify_unavailable_owned_pipeline_schedules(reporter_member.user.id, reporter_member.source)
      end
    end
  end

  describe '#notify_and_disable_all_pipeline_schedules_for_user' do
    let(:user) { create(:user) }
    let(:notification_service) { instance_double(NotificationService) }

    before do
      allow(NotificationService).to receive(:new).and_return(notification_service)
      allow(notification_service).to receive(:pipeline_schedule_owner_unavailable)
    end

    context 'when schedules exist' do
      let!(:active_schedules) { create_list(:ci_pipeline_schedule, 2, :nightly, owner: user) }

      it 'notifies and deactivates schedules' do
        user.notify_and_disable_all_pipeline_schedules_for_user(user.id)

        active_schedules.each do |schedule|
          expect(notification_service).to have_received(:pipeline_schedule_owner_unavailable)
            .with(schedule)
          expect(schedule.reload).not_to be_active
        end
      end
    end
  end
end
