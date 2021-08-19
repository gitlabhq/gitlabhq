# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryRemoveRemoteWorker do
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

      it 'does nothing when cannot obtain lease' do
        stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

        expect(project.repository)
          .not_to receive(:remove_remote)
        expect(subject)
          .not_to receive(:log_error)

        subject.perform(project.id, remote_name)
      end

      it 'does nothing when obtain a lease' do
        stub_exclusive_lease(lease_key, timeout: lease_timeout)

        expect(project.repository)
          .not_to receive(:remove_remote)

        subject.perform(project.id, remote_name)
      end
    end
  end
end
