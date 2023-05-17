# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker, feature_category: :system_access do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:worker) { described_class.new }

  include_examples 'an idempotent worker' do
    let(:job_args) { [project.id, user.id] }

    it 'does not change authorizations when run twice' do
      project.add_developer(user)

      user.project_authorizations.delete_all

      expect { worker.perform(project.id, user.id) }.to change { project.project_authorizations.reload.size }.by(1)
      expect { worker.perform(project.id, user.id) }.not_to change { project.project_authorizations.reload.size }
    end
  end

  describe '#perform' do
    it 'does not fail if the project does not exist' do
      expect do
        worker.perform(non_existing_record_id, user.id)
      end.not_to raise_error
    end

    it 'does not fail if the user does not exist' do
      expect do
        worker.perform(project.id, non_existing_record_id)
      end.not_to raise_error
    end

    it 'calls AuthorizedProjectUpdate::ProjectRecalculatePerUserService' do
      expect_next_instance_of(AuthorizedProjectUpdate::ProjectRecalculatePerUserService, project, user) do |service|
        expect(service).to receive(:execute)
      end

      worker.perform(project.id, user.id)
    end

    context 'exclusive lease' do
      let(:lock_key) { "#{described_class.superclass.name.underscore}/projects/#{project.id}" }
      let(:timeout) { 10.seconds }

      context 'when exclusive lease has not been taken' do
        it 'obtains a new exclusive lease' do
          expect_to_obtain_exclusive_lease(lock_key, timeout: timeout)

          worker.perform(project.id, user.id)
        end
      end

      context 'when exclusive lease has already been taken' do
        before do
          stub_exclusive_lease_taken(lock_key, timeout: timeout)
        end

        it 'raises an error' do
          expect { worker.perform(project.id, user.id) }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
        end
      end
    end
  end
end
