require 'rails_helper'

describe RepositoryRemoveRemoteWorker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let(:remote_name) { 'joe'}
    let!(:project) { create(:project, :repository) }

    context 'when it cannot obtain lease' do
      it 'logs error' do
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { nil }

        expect_any_instance_of(Repository).not_to receive(:remove_remote)
        expect(worker).to receive(:log_error).with('Cannot obtain an exclusive lease. There must be another instance already in execution.')

        worker.perform(project.id, remote_name)
      end
    end

    context 'when it gets the lease' do
      before do
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
      end

      context 'when project does not exist' do
        it 'returns nil' do
          expect(worker.perform(-1, 'remote_name')).to be_nil
        end
      end

      context 'when project exists' do
        it 'removes remote from repository' do
          masterrev = project.repository.find_branch('master').dereferenced_target

          create_remote_branch(remote_name, 'remote_branch', masterrev)

          expect_any_instance_of(Repository).to receive(:remove_remote).with(remote_name).and_call_original

          worker.perform(project.id, remote_name)
        end
      end
    end
  end

  def create_remote_branch(remote_name, branch_name, target)
    rugged = project.repository.rugged
    rugged.references.create("refs/remotes/#{remote_name}/#{branch_name}", target.id)
  end
end
