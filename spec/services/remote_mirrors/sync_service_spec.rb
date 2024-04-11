# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteMirrors::SyncService, feature_category: :source_code_management do
  subject(:sync_service) { described_class.new(project, current_user) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be_with_reload(:remote_mirror) { create(:remote_mirror, project: project, enabled: true) }

  let(:current_user) { maintainer }

  describe '#execute', :aggregate_failures do
    subject(:execute) { sync_service.execute(remote_mirror) }

    it 'triggers a mirror update worker' do
      expect { execute }.to change { RepositoryUpdateRemoteMirrorWorker.jobs.count }.by(1)

      is_expected.to be_success
    end

    context 'when user does not have permissions' do
      let(:current_user) { nil }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to eq('Access Denied')
      end
    end

    context 'when mirror is missing' do
      let(:remote_mirror) { nil }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to eq('Mirror does not exist')
      end
    end

    context 'when remote mirror is disabled' do
      before do
        remote_mirror.update!(enabled: false)
      end

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to match(/Cannot proceed with the push mirroring/)
      end
    end

    context 'when remote mirror update has been already started' do
      before do
        remote_mirror.update_start!
      end

      it 'does not trigger a mirror update worker' do
        expect { execute }.not_to change { RepositoryUpdateRemoteMirrorWorker.jobs.count }

        is_expected.to be_success
      end
    end
  end
end
