# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedules::DeactivateSchedulesWorker, feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }

  describe 'AuthorizationsRemovedEvent' do
    let(:data) { { project_id: project.id, user_ids: [user.id] } }
    let(:event) { ProjectAuthorizations::AuthorizationsRemovedEvent.new(data: data) }

    before do
      allow_next_found_instance_of(User) do |user|
        allow(user).to receive(:can?).and_return(true)
      end
    end

    it_behaves_like 'subscribes to event'

    context 'when user owns active schedules and cannot create pipelines' do
      before do
        allow_next_found_instance_of(User) do |user|
          allow(user).to receive(:can?).and_return(false)
        end
      end

      it 'deactivates the schedule and sends notification' do
        expect(NotificationService).to receive_message_chain(:new, :pipeline_schedule_owner_unavailable)
          .with(schedule)

        consume_event(subscriber: described_class, event: event)

        expect(schedule.reload).not_to be_active
      end
    end

    context 'when a different project access is removed' do
      let_it_be(:different_project) { create(:project) }
      let(:data) { { project_id: different_project.id, user_ids: [user.id] } }

      it 'does not deactivate the schedule' do
        expect(NotificationService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)

        expect(schedule.reload).to be_active
      end
    end

    context 'when multiple users are removed from the project' do
      let_it_be(:other_user) { create(:user) }
      let_it_be(:other_schedule) { create(:ci_pipeline_schedule, project: project, owner: other_user) }

      let(:data) { { project_id: project.id, user_ids: [user.id, other_user.id] } }

      before do
        allow_next_found_instance_of(User) do |user|
          allow(user).to receive(:can?).and_return(false)
        end
      end

      it 'deactivates schedules for all affected users' do
        consume_event(subscriber: described_class, event: event)

        expect(schedule.reload).not_to be_active
        expect(other_schedule.reload).not_to be_active
      end
    end
  end

  describe 'AuthorizationsAddedEvent' do
    let(:data) { { project_ids: [project.id], user_ids: [user.id] } }
    let(:event) { ProjectAuthorizations::AuthorizationsAddedEvent.new(data: data) }

    before do
      allow_next_found_instance_of(User) do |user|
        allow(user).to receive(:can?).and_return(true)
      end
    end

    it_behaves_like 'subscribes to event'

    context 'when user role changed and can no longer create pipelines' do
      before do
        allow_next_found_instance_of(User) do |user|
          allow(user).to receive(:can?).and_return(false)
        end
      end

      it 'deactivates the schedule and sends notification' do
        expect(NotificationService).to receive_message_chain(:new, :pipeline_schedule_owner_unavailable)
          .with(schedule)

        consume_event(subscriber: described_class, event: event)

        expect(schedule.reload).not_to be_active
      end
    end

    context 'when user role changed but still can create pipelines' do
      let(:data) { { project_ids: [project.id], user_ids: [user.id] } }

      it 'does not deactivate the schedule' do
        expect(NotificationService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)

        expect(schedule.reload).to be_active
      end
    end

    context 'when multiple users across multiple projects have roles changed' do
      let_it_be(:other_user) { create(:user) }
      let_it_be(:other_project) { create(:project) }
      let_it_be(:other_schedule) { create(:ci_pipeline_schedule, project: other_project, owner: other_user) }

      let(:data) { { project_ids: [project.id, other_project.id], user_ids: [user.id, other_user.id] } }

      before do
        allow_next_found_instance_of(User) do |user|
          allow(user).to receive(:can?).and_return(false)
        end
      end

      it 'deactivates schedules for all affected users across all projects' do
        consume_event(subscriber: described_class, event: event)

        expect(schedule.reload).not_to be_active
        expect(other_schedule.reload).not_to be_active
      end
    end
  end

  describe 'Missing IDs' do
    context 'when user_id is missing' do
      let(:data) { { project_id: project.id, user_ids: [] } }
      let(:event) { ProjectAuthorizations::AuthorizationsRemovedEvent.new(data: data) }

      it 'does not deactivate the schedule' do
        expect(Ci::PipelineSchedule).not_to receive(:active)

        consume_event(subscriber: described_class, event: event)

        expect(schedule.reload).to be_active
      end
    end

    context 'when project_ids are missing' do
      let(:data) { { project_ids: [], user_ids: [user.id] } }
      let(:event) { ProjectAuthorizations::AuthorizationsAddedEvent.new(data: data) }

      it 'does not deactivate the schedule' do
        expect(Ci::PipelineSchedule).not_to receive(:active)

        consume_event(subscriber: described_class, event: event)

        expect(schedule.reload).to be_active
      end
    end
  end
end
