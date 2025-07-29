# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SafeDisablePipelineVariablesWorker, feature_category: :ci_variables do
  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform_worker) { worker.perform(*job_args) }

    let(:job_args) { [current_user.id, group.id] }

    it_behaves_like 'an idempotent worker'

    shared_examples 'fails to execute the service' do
      it 'fails to execute and does not send email' do
        expect(worker).not_to receive(:log_extra_metadata_on_done)
        expect(::Ci::SafeDisablePipelineVariablesService).not_to receive(:new)
        expect(Notify).not_to receive(:pipeline_variables_migration_complete_email)

        perform_worker
      end
    end

    it 'executes SafeDisablePipelineVariablesService and sends email' do
      expected_response = ServiceResponse.success(payload: { updated_count: 5, skipped_count: 2 })
      email = instance_double(ActionMailer::MessageDelivery)

      expect_next_instance_of(::Ci::SafeDisablePipelineVariablesService) do |service|
        expect(service).to receive(:execute).and_return(expected_response)
      end

      expect(worker).to receive(:log_extra_metadata_on_done).with(:disabled_pipeline_variables_count, 5)
      expect(Notify).to receive(:pipeline_variables_migration_complete_email)
        .with(current_user, group, { updated_count: 5, skipped_count: 2 }).and_return(email)
      expect(email).to receive(:deliver_later)

      perform_worker
    end

    context 'when service response is an error' do
      before do
        expected_response = ServiceResponse.error(message: 'error')

        expect_next_instance_of(::Ci::SafeDisablePipelineVariablesService) do |service|
          allow(service).to receive(:execute).and_return(expected_response)
        end
      end

      it_behaves_like 'fails to execute the service'
    end

    context 'when group or user is not found' do
      before do
        expected_response = ServiceResponse.success(payload: { updated_count: 5 })

        allow_next_instance_of(::Ci::SafeDisablePipelineVariablesService) do |service|
          allow(service).to receive(:execute).and_return(expected_response)
        end
      end

      context 'and group does not exist' do
        let(:job_args) { [current_user.id, group.id + 1] }

        it_behaves_like 'fails to execute the service'
      end

      context 'and user does not exist' do
        let(:job_args) { [current_user.id + 1, group.id] }

        it_behaves_like 'fails to execute the service'
      end
    end
  end
end
