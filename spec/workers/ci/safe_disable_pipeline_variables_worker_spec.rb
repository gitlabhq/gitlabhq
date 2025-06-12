# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SafeDisablePipelineVariablesWorker, feature_category: :ci_variables do
  let_it_be(:group_id) { create(:group).id }
  let_it_be(:current_user_id) { create(:user).id }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform_worker) { worker.perform(*job_args) }

    let(:job_args) { [current_user_id, group_id] }

    it_behaves_like 'an idempotent worker'

    shared_examples 'fails to execute the service' do
      it 'fails to execute' do
        expect(worker).not_to receive(:log_extra_metadata_on_done)
        expect(::Ci::SafeDisablePipelineVariablesService).not_to receive(:new)

        perform_worker
      end
    end

    it 'executes SafeDisablePipelineVariablesService' do
      expected_response = ServiceResponse.success(payload: { updated_count: 5 })

      expect_next_instance_of(::Ci::SafeDisablePipelineVariablesService) do |service|
        expect(service).to receive(:execute).and_return(expected_response)
      end

      expect(worker).to receive(:log_extra_metadata_on_done).with(:disabled_pipeline_variables_count, 5)

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
        let(:job_args) { [current_user_id, group_id + 1] }

        it_behaves_like 'fails to execute the service'
      end

      context 'and user does not exist' do
        let(:job_args) { [current_user_id + 1, group_id] }

        it_behaves_like 'fails to execute the service'
      end
    end
  end
end
