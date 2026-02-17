# frozen_string_literal: true

require 'spec_helper'
require_relative 'event_shared_examples'

RSpec.describe Gitlab::Database::BackgroundOperation::Observability::Events::JobTransitionEvent, feature_category: :database do
  shared_examples 'logging for the given record type' do
    let(:worker) { record.worker }

    context 'when job transitions with no error' do
      let(:attributes) { { previous_state: :pending, new_state: :running } }
      let(:expected_payload) do
        {
          message: 'background_operation_job_transition_event',
          previous_state: :pending,
          new_state: :running,
          worker_id: record.worker_id,
          worker_partition: record.worker_partition,
          job_class_name: worker.job_class_name,
          batch_class_name: worker.batch_class_name,
          table_name: worker.table_name,
          column_name: worker.column_name,
          attempts: record.attempts,
          exception_class: nil,
          exception_message: nil
        }
      end

      it_behaves_like 'logging the correct payload'
    end

    context 'when job transitions includes an error' do
      let(:attributes) { { previous_state: :running, new_state: :failed, error: StandardError.new('timeout') } }
      let(:expected_payload) do
        { exception_class: StandardError, exception_message: 'timeout' }
      end

      it_behaves_like 'logging the correct payload'
    end
  end

  describe '#payload' do
    context 'with BackgroundOperation::Job record' do
      let(:record) { FactoryBot.create(:background_operation_job) }

      it_behaves_like 'logging for the given record type'
    end

    context 'with BackgroundOperation::JobCellLocal record' do
      let(:record) { FactoryBot.create(:background_operation_job_cell_local) }

      it_behaves_like 'logging for the given record type'
    end
  end
end
