require 'spec_helper'

describe ProjectDestroyWorker do
  let(:project) { create(:project, :repository, pending_delete: true) }
  let(:path) { project.repository.path_to_repo }

  subject { described_class.new }

  describe '#perform' do
    it 'deletes the project' do
      subject.perform(project.id, project.owner.id, {})

      expect(Project.all).not_to include(project)
      expect(Dir.exist?(path)).to be_falsey
    end

    it 'deletes the project but skips repo deletion' do
      subject.perform(project.id, project.owner.id, { "skip_repo" => true })

      expect(Project.all).not_to include(project)
      expect(Dir.exist?(path)).to be_truthy
    end

    describe 'when StandardError is raised' do
      it 'reverts pending_delete attribute with a error message' do
        allow_any_instance_of(::Projects::DestroyService).to receive(:execute).and_raise(StandardError, "some error message")

        expect do
          subject.perform(project.id, project.owner.id, {})
        end.to change { project.reload.pending_delete }.from(true).to(false)

        expect(Project.all).to include(project)
        expect(project.delete_error).to eq("some error message")
      end
    end
  end
end
