# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::TransferOrganizationWorker, feature_category: :runner_core do
  let_it_be(:old_organization, freeze: true) { create(:organization) }
  let_it_be(:new_organization, freeze: true) { create(:organization) }
  let_it_be(:group, freeze: true) { create(:group, organization: old_organization) }

  describe '#perform' do
    let(:job_args) { [group.id, old_organization.id, new_organization.id] }
    let(:worker) { described_class.new }

    subject(:perform) { worker.perform(*job_args) }

    it 'delegates to Organizations::Transfer::CiRunnersService and logs the result status' do
      expect_next_instance_of(
        Organizations::Transfer::CiRunnersService,
        group: group,
        old_organization: old_organization,
        new_organization: new_organization
      ) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      expect(worker).to receive(:log_extra_metadata_on_done).with(:status, :success)
      expect(worker).not_to receive(:log_extra_metadata_on_done).with(:reason, anything)

      perform
    end

    shared_examples 'passes the missing record to the service and logs the error' do
      it 'passes nil for the missing record and logs the error status and reason' do
        expect_next_instance_of(Organizations::Transfer::CiRunnersService, **service_args) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        expect(worker).to receive(:log_extra_metadata_on_done).with(:status, :error)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:reason, :not_found)

        perform
      end
    end

    context 'when group does not exist' do
      let(:job_args) { [non_existing_record_id, old_organization.id, new_organization.id] }

      it_behaves_like 'passes the missing record to the service and logs the error' do
        let(:service_args) { { group: nil, old_organization: old_organization, new_organization: new_organization } }
      end
    end

    context 'when old organization does not exist' do
      let(:job_args) { [group.id, non_existing_record_id, new_organization.id] }

      it_behaves_like 'passes the missing record to the service and logs the error' do
        let(:service_args) { { group: group, old_organization: nil, new_organization: new_organization } }
      end
    end

    context 'when new organization does not exist' do
      let(:job_args) { [group.id, old_organization.id, non_existing_record_id] }

      it_behaves_like 'passes the missing record to the service and logs the error' do
        let(:service_args) { { group: group, old_organization: old_organization, new_organization: nil } }
      end
    end

    it_behaves_like 'an idempotent worker'
  end
end
