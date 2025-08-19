# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MarkForDeletionService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be_with_reload(:project) do
    create(:project, :repository, namespace: user.namespace)
  end

  let(:original_project_path) { project.path }
  let(:original_project_name) { project.name }
  let(:service) { described_class.new(project, user) }
  let(:notification_service) { instance_double(NotificationService) }

  subject(:result) { service.execute }

  before do
    allow(NotificationService).to receive(:new).and_return(notification_service)
    allow(notification_service).to receive(:project_was_moved).with(any_args)
    allow(notification_service).to receive(:project_scheduled_for_deletion).with(project)
  end

  it 'marks project as archived and marked for deletion', :aggregate_failures do
    expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
      .with(project.namespace_id).and_call_original

    expect(result).to be_success

    expect(Project.unscoped.all).to include(project)
    expect(project.reload.archived).to be(false)
    expect(project.reload).to be_self_deletion_scheduled
    expect(project.reload.self_deletion_scheduled_deletion_created_on).not_to be_nil
    expect(project.reload.deleting_user).to eq(user)
  end

  context 'for a project that has not been marked for deletion' do
    context 'when a project under the group has a container image' do
      before do
        allow(project).to receive(:has_container_registry_tags?).and_return(true)
      end

      it 'returns error' do
        expect(result).to be_error
        expect(result.message).to include('Cannot rename or delete project because it contains container registry tags')
      end
    end

    it { is_expected.to be_success }

    it 'renames project name' do
      expect { result }.to change {
        project.name
      }.from(original_project_name).to("#{original_project_name}-deletion_scheduled-#{project.id}")
    end

    it 'renames project path' do
      expect { result }.to change {
        project.path
      }.from(original_project_path).to("#{original_project_path}-deletion_scheduled-#{project.id}")
    end

    it 'logs the events' do
      allow(Gitlab::AppLogger).to receive(:info).and_call_original
      expect(Gitlab::AppLogger).to receive(:info).with(
        "User #{user.id} marked project #{project.full_path}-deletion_scheduled-#{project.id} for deletion"
      )

      result
    end

    it 'sends notification' do
      expect(notification_service).to receive(:project_scheduled_for_deletion).with(project)

      result
    end

    context 'when deletion schedule creation fails' do
      before do
        allow_next_instance_of(Projects::UpdateService) do |project_update_service|
          allow(project_update_service).to receive(:execute)
            .and_return({ status: :error, message: 'error message' })
          allow(project).to receive_message_chain(:errors, :full_messages)
            .and_return(['error message'])
        end
      end

      it 'returns error' do
        expect(result).to be_error
        expect(result.errors).to eq(['error message'])
      end

      it 'does not send notification' do
        expect(NotificationService).not_to receive(:new)

        result
      end
    end
  end

  context 'when project is already marked for deletion' do
    let(:marked_for_deletion_at) { 2.days.ago }

    before do
      project.update!(marked_for_deletion_at: marked_for_deletion_at)
    end

    it 'does not change the attributes associated with delayed deletion' do
      expect(result).to be_error
      expect(project).to be_self_deletion_scheduled
      expect(project.self_deletion_scheduled_deletion_created_on).to eq(marked_for_deletion_at.to_date)
    end

    it 'does not send notification' do
      # eager-load service to avoid false positive NotificationService.new calls
      service

      expect(NotificationService).not_to receive(:new)
      expect(result).to be_error
    end

    it 'returns error' do
      expect(result).to be_error
      expect(result.message).to eq('Project has been already marked for deletion')
    end
  end

  context 'with a user that cannot admin the project' do
    let(:project) { build(:project) }

    it 'does not mark the project for deletion' do
      expect(result).to be_error
      expect(project).not_to be_self_deletion_scheduled
    end

    it 'returns error' do
      expect(result).to be_error
      expect(result.message).to eq('You are not authorized to perform this action')
    end
  end
end
