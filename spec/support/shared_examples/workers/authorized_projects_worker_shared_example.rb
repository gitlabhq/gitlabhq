# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "refreshes user's project authorizations" do
  describe '#perform' do
    let_it_be(:user) { create(:user) }

    let(:service) { instance_double(Users::RefreshAuthorizedProjectsService) }

    subject(:job) { described_class.new }

    it 'calls refresh authorized projects service without redis lock' do
      expect(service).to receive(:execute_without_lease)

      expect(Users::RefreshAuthorizedProjectsService)
        .to receive(:new)
        .with(user, source: described_class.name)
        .and_return(service)

      job.perform(user.id)
    end

    context 'when the user is not found' do
      it 'does not call the refresh authorized projects service' do
        expect(Users::RefreshAuthorizedProjectsService).not_to receive(:new)

        job.perform(nil)
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { user.id }

      it 'does not change authorizations when run twice' do
        group = create(:group)
        create(:project, namespace: group)
        group.add_developer(user)

        # Delete the authorization created by the after save hook of the member
        # created above.
        user.project_authorizations.delete_all

        expect { job.perform(user.id) }.to change { user.project_authorizations.reload.size }.by(1)
        expect { job.perform(user.id) }.not_to change { user.project_authorizations.reload.size }
      end
    end
  end
end
