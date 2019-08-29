# frozen_string_literal: true

require 'spec_helper'

describe RepositoryRemoveRemoteWorker do
  include ExclusiveLeaseHelpers
  include GitHelpers

  describe '#perform' do
    let!(:project) { create(:project, :repository) }
    let(:remote_name) { 'joe'}
    let(:lease_key) { "remove_remote_#{project.id}_#{remote_name}" }
    let(:lease_timeout) { RepositoryRemoveRemoteWorker::LEASE_TIMEOUT }

    it 'returns nil when project does not exist' do
      expect(subject.perform(-1, 'remote_name')).to be_nil
    end

    context 'when project exists' do
      before do
        allow(Project)
          .to receive(:find_by)
          .with(id: project.id)
          .and_return(project)
      end

      it 'does not remove remote when cannot obtain lease' do
        stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

        expect(project.repository)
          .not_to receive(:remove_remote)

        expect(subject)
          .to receive(:log_error)
          .with('Cannot obtain an exclusive lease. There must be another instance already in execution.')

        subject.perform(project.id, remote_name)
      end

      it 'removes remote from repository when obtain a lease' do
        stub_exclusive_lease(lease_key, timeout: lease_timeout)
        masterrev = project.repository.find_branch('master').dereferenced_target
        create_remote_branch(remote_name, 'remote_branch', masterrev)

        expect(project.repository)
          .to receive(:remove_remote)
          .with(remote_name)
          .and_call_original

        subject.perform(project.id, remote_name)
      end
    end
  end

  def create_remote_branch(remote_name, branch_name, target)
    rugged = rugged_repo(project.repository)

    rugged.references.create("refs/remotes/#{remote_name}/#{branch_name}", target.id)
  end
end
