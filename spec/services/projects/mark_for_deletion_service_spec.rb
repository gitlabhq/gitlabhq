# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MarkForDeletionService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be_with_reload(:project) do
    create(:project, :repository, namespace: user.namespace)
  end

  let(:original_project_path) { project.path }
  let(:original_project_name) { project.name }
  let(:licensed) { false }

  subject(:result) { described_class.new(project, user).execute(licensed: licensed) }

  context 'with downtier_delayed_deletion feature flag enabled' do
    context 'when marking project for deletion' do
      it 'marks project as archived and marked for deletion', :aggregate_failures do
        expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
         .with(project.namespace_id).and_call_original
        expect(result[:status]).to eq(:success)
        expect(Project.unscoped.all).to include(project)
        expect(project.archived).to be(true)
        expect(project.marked_for_deletion_at).not_to be_nil
        expect(project.deleting_user).to eq(user)
        expect(project).not_to be_hidden
      end

      it 'renames project name' do
        expect { result }.to change {
          project.name
        }.from(original_project_name).to("#{original_project_name}-deleted-#{project.id}")
      end

      it 'renames project path' do
        expect { result }.to change {
          project.path
        }.from(original_project_path).to("#{original_project_path}-deleted-#{project.id}")
      end

      it 'logs the event' do
        allow(Gitlab::AppLogger).to receive(:info).and_call_original
        expect(Gitlab::AppLogger).to receive(:info).with(
          "User #{user.id} marked project #{project.full_path}-deleted-#{project.id} for deletion"
        )

        result
      end
    end

    context 'when marking project for deletion once again' do
      let(:marked_for_deletion_at) { 2.days.ago }

      it 'does not change original date', :freeze_time, :aggregate_failures do
        project.update!(marked_for_deletion_at: marked_for_deletion_at)

        expect(result[:status]).to eq(:success)
        expect(project.marked_for_deletion_at).to eq(marked_for_deletion_at.to_date)
      end
    end
  end

  context 'with downtier_delayed_deletion feature flag disabled' do
    before do
      stub_feature_flags(downtier_delayed_deletion: false)
    end

    it 'returns an error response' do
      expect(result).to eq(status: :error, message: 'Cannot mark project for deletion: feature not supported')
    end

    context 'when the feature is licensed', unless: Gitlab.ee? do
      let(:licensed) { true }

      it 'is successful' do
        expect(result[:status]).to eq(:success)
      end
    end
  end
end
