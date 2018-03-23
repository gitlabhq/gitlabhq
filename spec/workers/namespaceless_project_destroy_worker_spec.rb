require 'spec_helper'

describe NamespacelessProjectDestroyWorker do
  include ProjectForksHelper

  subject { described_class.new }

  before do
    # Stub after_save callbacks that will fail when Project has no namespace
    allow_any_instance_of(Project).to receive(:ensure_storage_path_exists).and_return(nil)
    allow_any_instance_of(Project).to receive(:update_project_statistics).and_return(nil)
  end

  describe '#perform' do
    context 'project has namespace' do
      it 'does not do anything' do
        project = create(:project)

        subject.perform(project.id)

        expect(Project.unscoped.all).to include(project)
      end
    end

    # Only possible with schema 20180222043024 and lower.
    # Project#namespace_id has not null constraint since then
    context 'project has no namespace', :migration, schema: 20180222043024 do
      let!(:project) do
        project = build(:project, namespace_id: nil)
        project.save(validate: false)
        project
      end

      context 'project not a fork of another project' do
        it "truncates the project's team" do
          expect_any_instance_of(ProjectTeam).to receive(:truncate)

          subject.perform(project.id)
        end

        it 'deletes the project' do
          subject.perform(project.id)

          expect(Project.unscoped.all).not_to include(project)
        end

        it 'does not call unlink_fork' do
          is_expected.not_to receive(:unlink_fork)

          subject.perform(project.id)
        end

        it 'does not do anything in Project#remove_pages method' do
          expect(Gitlab::PagesTransfer).not_to receive(:new)

          subject.perform(project.id)
        end
      end

      context 'project forked from another' do
        let!(:parent_project) { create(:project) }
        let(:project) do
          namespaceless_project = fork_project(parent_project)
          namespaceless_project.namespace_id = nil
          namespaceless_project.save(validate: false)
          namespaceless_project
        end

        it 'closes open merge requests' do
          merge_request = create(:merge_request, source_project: project, target_project: parent_project)

          subject.perform(project.id)

          expect(merge_request.reload).to be_closed
        end

        it 'destroys the link' do
          subject.perform(project.id)

          expect(parent_project.forked_project_links).to be_empty
        end
      end
    end

    context 'project has non-existing namespace' do
      let!(:project) do
        project = build(:project, namespace_id: Namespace.maximum(:id).to_i.succ)
        project.save(validate: false)
        project
      end

      it 'deletes the project' do
        subject.perform(project.id)

        expect(Project.unscoped.all).not_to include(project)
      end
    end
  end
end
