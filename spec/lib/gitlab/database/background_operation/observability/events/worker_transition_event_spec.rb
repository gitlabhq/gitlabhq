# frozen_string_literal: true

require 'spec_helper'
require_relative 'event_shared_examples'

RSpec.describe Gitlab::Database::BackgroundOperation::Observability::Events::WorkerTransitionEvent, feature_category: :database do
  shared_examples 'logging for the given record type' do
    context 'when job transitions with no error' do
      let(:attributes) { { previous_state: :pending, new_state: :running } }
      let(:expected_payload) do
        {
          message: 'background_operation_worker_transition_event',
          previous_state: :pending,
          new_state: :running,
          on_hold_until: record.on_hold_until,
          priority: record.priority,
          job_class_name: record.job_class_name,
          batch_class_name: record.batch_class_name,
          table_name: record.table_name,
          column_name: record.column_name,
          gitlab_schema: record.gitlab_schema,
          job_arguments: record.job_arguments
        }
      end

      it_behaves_like 'logging the correct payload'
    end
  end

  describe '#payload' do
    context 'with BackgroundOperation::Worker as record' do
      let(:record) { FactoryBot.create(:background_operation_worker) }

      it_behaves_like 'logging for the given record type'
    end

    context 'with BackgroundOperation::WorkerCellLocal as record' do
      let(:record) { FactoryBot.create(:background_operation_worker_cell_local) }

      it_behaves_like 'logging for the given record type'
    end
  end
end
