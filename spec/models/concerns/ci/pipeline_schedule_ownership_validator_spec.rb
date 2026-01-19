# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineScheduleOwnershipValidator, feature_category: :continuous_integration do
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
