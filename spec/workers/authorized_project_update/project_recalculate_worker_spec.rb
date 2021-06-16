# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectRecalculateWorker do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project) }

  subject(:worker) { described_class.new }

  it 'is labeled as high urgency' do
    expect(described_class.get_urgency).to eq(:high)
  end

  include_examples 'an idempotent worker' do
    let(:job_args) { project.id }

    it 'does not change authorizations when run twice' do
      user = create(:user)
      project.add_developer(user)

      user.project_authorizations.delete_all

      expect { worker.perform(project.id) }.to change { project.project_authorizations.reload.size }.by(1)
      expect { worker.perform(project.id) }.not_to change { project.project_authorizations.reload.size }
    end
  end

  describe '#perform' do
    it 'does not fail if the project does not exist' do
      expect do
        worker.perform(non_existing_record_id)
      end.not_to raise_error
    end

    it 'calls AuthorizedProjectUpdate::ProjectRecalculateService' do
      expect_next_instance_of(AuthorizedProjectUpdate::ProjectRecalculateService, project) do |service|
        expect(service).to receive(:execute)
      end

      worker.perform(project.id)
    end

    context 'exclusive lease' do
      let(:lock_key) { "#{described_class.name.underscore}/#{project.root_namespace.id}" }
      let(:timeout) { 10.seconds }

      context 'when exclusive lease has not been taken' do
        it 'obtains a new exclusive lease' do
          expect_to_obtain_exclusive_lease(lock_key, timeout: timeout)

          worker.perform(project.id)
        end
      end

      context 'when exclusive lease has already been taken' do
        before do
          stub_exclusive_lease_taken(lock_key, timeout: timeout)
        end

        it 'raises an error' do
          expect { worker.perform(project.id) }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
        end
      end
    end
  end
end
