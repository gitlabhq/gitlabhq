# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::ImportCompletionNotificationWorker, feature_category: :importers do
  include ProjectForksHelper

  let_it_be(:project_creator) { create(:user, :with_namespace) }
  let_it_be(:group_owner) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }

  let_it_be_with_reload(:project) do
    create(:project,
      :import_user_mapping_enabled,
      namespace: group,
      import_type: Import::SOURCE_GITHUB,
      creator: project_creator,
      import_url: 'https://user:password@example.com'
    )
  end

  let(:worker) { described_class.new }
  let(:user_mapping_enabled) { true }
  let(:safe_import_url) { project.safe_import_url(masked: false) }

  before_all do
    group.add_owner(group_owner)
    group.add_owner(project.creator)
  end

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      let(:job_args) do
        [
          project.id,
          {
            'user_mapping_enabled' => false,
            'notify_group_owners' => false,
            'safe_import_url' => safe_import_url
          }
        ]
      end
    end

    it 'sends notification to project creator and group owners' do
      allow(Notify).to receive(:project_import_complete).and_call_original

      worker.perform(
        project.id,
        'user_mapping_enabled' => user_mapping_enabled,
        'notify_group_owners' => true,
        'safe_import_url' => safe_import_url
      )

      expect(Notify)
        .to have_received(:project_import_complete)
        .with(project.id, project.creator_id, true, safe_import_url)

      expect(Notify)
        .to have_received(:project_import_complete)
        .with(project.id, group_owner.id, true, safe_import_url)
    end

    context 'when project cannot be found' do
      it 'does not send a notification' do
        expect(Notify).not_to receive(:project_import_complete)

        worker.perform(
          non_existing_record_id,
          'user_mapping_enabled' => false,
          'notify_group_owners' => false,
          'safe_import_url' => safe_import_url
        )
      end
    end

    context 'when project is forked' do
      it 'does not send a notification' do
        fork = fork_project(project, group_owner)

        expect(Notify).not_to receive(:project_import_complete)

        worker.perform(
          fork.id,
          'user_mapping_enabled' => false,
          'notify_group_owners' => false,
          'safe_import_url' => safe_import_url
        )
      end
    end

    context 'when project has remote mirror' do
      before do
        allow(Project).to receive(:find_by_id).with(project.id).and_return(project)
        allow(project).to receive(:mirror?).and_return(true)
      end

      it 'does not send notification' do
        expect(Notify).not_to receive(:project_import_complete)

        worker.perform(
          project.id,
          'user_mapping_enabled' => false,
          'notify_group_owners' => false,
          'safe_import_url' => safe_import_url
        )
      end
    end

    context 'when project is not one of the supported import types' do
      it 'does not send notification' do
        project.update!(import_type: 'gitlab_custom_project_template')

        expect(Notify).not_to receive(:project_import_complete)

        worker.perform(
          project.id,
          'user_mapping_enabled' => false,
          'notify_group_owners' => false,
          'safe_import_url' => safe_import_url
        )
      end
    end

    context 'when project creator is not a human' do
      it 'sends a completion email only to group owners' do
        project.creator.update!(user_type: 'import_user')

        allow(Notify).to receive(:project_import_complete).and_call_original

        worker.perform(
          project.id,
          'user_mapping_enabled' => user_mapping_enabled,
          'notify_group_owners' => true,
          'safe_import_url' => safe_import_url
        )

        expect(Notify)
          .not_to have_received(:project_import_complete)
          .with(project.id, project.creator_id, true, safe_import_url)

        expect(Notify)
          .to have_received(:project_import_complete)
          .with(project.id, group_owner.id, true, safe_import_url)
      end
    end

    context 'when project is imported to a personal namespace' do
      it 'sends a completion email only to project creator' do
        project.update!(namespace: project.creator.namespace)

        allow(Notify).to receive(:project_import_complete).and_call_original

        worker.perform(
          project.id,
          'user_mapping_enabled' => user_mapping_enabled,
          'notify_group_owners' => true,
          'safe_import_url' => safe_import_url
        )

        expect(Notify)
          .to have_received(:project_import_complete)
          .with(project.id, project.creator_id, true, safe_import_url)

        expect(Notify)
          .not_to have_received(:project_import_complete)
          .with(project.id, group_owner.id, true, safe_import_url)

        project.update!(namespace: group)
      end
    end

    context 'when project uses token for authentication' do
      it 'sends a completion email with safe import url' do
        project.update!(import_url: 'https://token@example.com')

        allow(Notify).to receive(:project_import_complete).and_call_original

        worker.perform(
          project.id,
          'user_mapping_enabled' => user_mapping_enabled,
          'notify_group_owners' => true,
          'safe_import_url' => safe_import_url
        )

        expect(Notify)
          .to have_received(:project_import_complete)
          .with(project.id, project.creator_id, true, 'https://example.com')
      end
    end
  end
end
