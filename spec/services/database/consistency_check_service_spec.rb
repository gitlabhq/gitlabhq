# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::ConsistencyCheckService do
  let(:batch_size) { 5 }
  let(:max_batches) { 2 }

  before do
    stub_const("Gitlab::Database::ConsistencyChecker::BATCH_SIZE", batch_size)
    stub_const("Gitlab::Database::ConsistencyChecker::MAX_BATCHES", max_batches)
  end

  after do
    redis_shared_state_cleanup!
  end

  subject(:consistency_check_service) do
    described_class.new(
      source_model: Namespace,
      target_model: Ci::NamespaceMirror,
      source_columns: %w[id traversal_ids],
      target_columns: %w[namespace_id traversal_ids]
    )
  end

  describe '#random_start_id' do
    let(:batch_size) { 5 }

    before do
      create_list(:namespace, 50) # This will also create Ci::NameSpaceMirror objects
    end

    it 'generates a random start_id within the records ids' do
      10.times do
        start_id = subject.send(:random_start_id)
        expect(start_id).to be_between(Namespace.first.id, Namespace.last.id).inclusive
      end
    end
  end

  describe '#execute' do
    let(:empty_results) do
      { batches: 0, matches: 0, mismatches: 0, mismatches_details: [] }
    end

    context 'when empty tables' do
      it 'returns results with zero counters' do
        result = consistency_check_service.execute

        expect(result).to eq(empty_results)
      end

      it 'does not call the ConsistencyCheckService' do
        expect(Gitlab::Database::ConsistencyChecker).not_to receive(:new)
        consistency_check_service.execute
      end
    end

    context 'no cursor has been saved before' do
      let(:selected_start_id) { Namespace.order(:id).limit(5).pluck(:id).last }
      let(:expected_next_start_id) { selected_start_id + batch_size * max_batches }

      before do
        create_list(:namespace, 50) # This will also create Ci::NameSpaceMirror objects
        expect(consistency_check_service).to receive(:random_start_id).and_return(selected_start_id)
      end

      it 'picks a random start_id' do
        expected_result = {
          batches: 2,
          matches: 10,
          mismatches: 0,
          mismatches_details: [],
          start_id: selected_start_id,
          next_start_id: expected_next_start_id
        }
        expect(consistency_check_service.execute).to eq(expected_result)
      end

      it 'calls the ConsistencyCheckService with the expected parameters' do
        allow_next_instance_of(Gitlab::Database::ConsistencyChecker) do |instance|
          expect(instance).to receive(:execute).with(start_id: selected_start_id).and_return({
            batches: 2,
            next_start_id: expected_next_start_id,
            matches: 10,
            mismatches: 0,
            mismatches_details: []
          })
        end

        expect(Gitlab::Database::ConsistencyChecker).to receive(:new).with(
          source_model: Namespace,
          target_model: Ci::NamespaceMirror,
          source_columns: %w[id traversal_ids],
          target_columns: %w[namespace_id traversal_ids]
        ).and_call_original

        expected_result = {
          batches: 2,
          start_id: selected_start_id,
          next_start_id: expected_next_start_id,
          matches: 10,
          mismatches: 0,
          mismatches_details: []
        }
        expect(consistency_check_service.execute).to eq(expected_result)
      end

      it 'saves the next_start_id in Redis for he next iteration' do
        expect(consistency_check_service).to receive(:save_next_start_id).with(expected_next_start_id).and_call_original
        consistency_check_service.execute
      end
    end

    context 'cursor saved in Redis and moving' do
      let(:first_namespace_id) { Namespace.order(:id).first.id }
      let(:second_namespace_id) { Namespace.order(:id).second.id }

      before do
        create_list(:namespace, 30) # This will also create Ci::NameSpaceMirror objects
      end

      it "keeps moving the cursor with each call to the service" do
        expect(consistency_check_service).to receive(:random_start_id).at_most(:once).and_return(first_namespace_id)

        allow_next_instance_of(Gitlab::Database::ConsistencyChecker) do |instance|
          expect(instance).to receive(:execute).ordered.with(start_id: first_namespace_id).and_call_original
          expect(instance).to receive(:execute).ordered.with(start_id: first_namespace_id + 10).and_call_original
          expect(instance).to receive(:execute).ordered.with(start_id: first_namespace_id + 20).and_call_original
          # Gets back to the start of the table
          expect(instance).to receive(:execute).ordered.with(start_id: first_namespace_id).and_call_original
        end

        4.times do
          consistency_check_service.execute
        end
      end

      it "keeps moving the cursor from any start point" do
        expect(consistency_check_service).to receive(:random_start_id).at_most(:once).and_return(second_namespace_id)

        allow_next_instance_of(Gitlab::Database::ConsistencyChecker) do |instance|
          expect(instance).to receive(:execute).ordered.with(start_id: second_namespace_id).and_call_original
          expect(instance).to receive(:execute).ordered.with(start_id: second_namespace_id + 10).and_call_original
        end

        2.times do
          consistency_check_service.execute
        end
      end
    end
  end
end
