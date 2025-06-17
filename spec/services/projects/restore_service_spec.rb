# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RestoreService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user, :with_namespace) }

  subject(:execute) { described_class.new(project, user).execute }

  context 'when restoring project' do
    let_it_be_with_reload(:project) do
      create(
        :project,
        :repository,
        :aimed_for_deletion,
        path: 'project-1-deleted-177483',
        name: 'Project1 Name-deleted-177483',
        namespace: user.namespace,
        archived: true,
        hidden: true
      )
    end

    it 'marks project as not hidden, unarchived and not marked for deletion' do
      expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
        .with(project.namespace.id).and_call_original

      execute

      expect(Project.unscoped.all).to include(project)
      expect(project.archived).to be(false)
      expect(project.hidden).to be(false)
      expect(project.marked_for_deletion_at).to be_nil
      expect(project.deleting_user).to be_nil
    end

    it 'destroys deletion schedule' do
      execute

      expect(project.project_namespace.reload.deletion_schedule).to be_nil
    end

    context 'when the original project path is not taken' do
      it 'renames the project back to its original path' do
        expect { execute }.to change { project.path }.from("project-1-deleted-177483").to("project-1")
      end

      it 'renames the project back to its original name' do
        expect { execute }.to change { project.name }.from("Project1 Name-deleted-177483").to("Project1 Name")
      end
    end

    context 'when the original project name has been taken' do
      before do
        create(:project, path: 'project-1', name: 'Project1 Name', namespace: user.namespace, deleting_user: user)
      end

      it 'renames the project back to its original path with a suffix' do
        expect { execute }.to change { project.path }.from("project-1-deleted-177483").to(/project-1-[a-zA-Z0-9]{5}/)
      end

      it 'renames the project back to its original name with a suffix' do
        expect { execute }.to change { project.name }.from("Project1 Name-deleted-177483")
          .to(/Project1 Name-[a-zA-Z0-9]{5}/)
      end

      it 'uses the same suffix for both the path and name' do
        execute

        path_suffix = project.path.split('-')[-1]
        name_suffix = project.name.split('-')[-1]

        expect(path_suffix).to eq(name_suffix)
      end
    end

    context 'when the original project path does not contain the -deleted- suffix' do
      let_it_be(:project) do
        create(
          :project,
          :repository,
          namespace: user.namespace,
          marked_for_deletion_at: 1.day.ago,
          deleting_user: user,
          archived: true
        )
      end

      it 'renames the project back to its original path' do
        expect { execute }.not_to change { project.path }
      end

      it 'renames the project back to its original name' do
        expect { execute }.not_to change { project.name }
      end
    end
  end

  context 'when restoring project already in process of removal' do
    let_it_be(:project) { create(:project, :aimed_for_deletion, pending_delete: true) }

    it 'does not allow to restore' do
      result = execute

      expect(result[:status]).to be(:error)
      expect(result[:message]).to be(_('Project already deleted'))
    end
  end

  context 'when restoring project not marked for deletion' do
    let_it_be(:project) { create(:project) }

    it 'returns error result' do
      result = execute

      expect(result[:status]).to be(:error)
      expect(result[:message]).to be(_('Project has not been marked for deletion'))
    end
  end
end
