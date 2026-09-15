# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::TransferUserAgentDetailsWorker, feature_category: :instance_resiliency do
  let_it_be(:old_organization, freeze: true) { create(:organization) }
  let_it_be(:new_organization, freeze: true) { create(:organization) }
  let_it_be(:group, freeze: true) { create(:group, organization: old_organization) }

  describe '#perform' do
    let(:job_args) { [group.id, old_organization.id, new_organization.id] }
    let(:worker) { described_class.new }

    subject(:perform) { worker.perform(*job_args) }

    it 'delegates to Organizations::Transfer::UserAgentDetailsService' do
      expect_next_instance_of(
        Organizations::Transfer::UserAgentDetailsService,
        group: group,
        old_organization: old_organization,
        new_organization: new_organization
      ) do |service|
        expect(service).to receive(:execute)
      end

      perform
    end

    shared_examples 'logs and does not call the service' do
      it 'logs and does not call the service' do
        expect(Sidekiq.logger).to receive(:info).with(hash_including(log_payload))
        expect(Organizations::Transfer::UserAgentDetailsService).not_to receive(:new)

        perform
      end
    end

    context 'when group does not exist' do
      let(:job_args) { [non_existing_record_id, old_organization.id, new_organization.id] }

      it_behaves_like 'logs and does not call the service' do
        let(:log_payload) do
          { 'message' => 'Group not found.', 'group_id' => non_existing_record_id }
        end
      end
    end

    context 'when old organization does not exist' do
      let(:job_args) { [group.id, non_existing_record_id, new_organization.id] }

      it_behaves_like 'logs and does not call the service' do
        let(:log_payload) do
          { 'message' => 'Old organization not found.', 'organization_id' => non_existing_record_id }
        end
      end
    end

    context 'when new organization does not exist' do
      let(:job_args) { [group.id, old_organization.id, non_existing_record_id] }

      it_behaves_like 'logs and does not call the service' do
        let(:log_payload) do
          { 'message' => 'New organization not found.', 'organization_id' => non_existing_record_id }
        end
      end
    end

    it_behaves_like 'an idempotent worker' do
      let!(:detail) do
        create(:user_agent_detail,
          subject: create(:issue, project: create(:project, namespace: group,
            organization: old_organization)),
          organization: old_organization)
      end

      it 'moves the details to the new organization' do
        perform

        expect(detail.reload.organization_id).to eq(new_organization.id)
      end
    end
  end
end
