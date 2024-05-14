# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::ConsistencyCheckService, feature_category: :cell do
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

  describe '#min_id' do
    before do
      create_list(:namespace, 3)
    end

    it 'returns the id of the first record in the database' do
      expect(subject.send(:min_id)).to eq(Namespace.first.id)
    end
  end

  describe '#max_id' do
    before do
      create_list(:namespace, 3)
    end

    it 'returns the id of the first record in the database' do
      expect(subject.send(:max_id)).to eq(Namespace.last.id)
    end
  end

  describe '#random_start_id' do
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
      let(:min_id) { Namespace.first.id }
      let(:max_id) { Namespace.last.id }

      before do
        create_list(:namespace, 50) # This will also create Ci::NameSpaceMirror objects
      end

      it 'picks a random start_id within the range of available item ids' do
        expected_result = {
          batches: be_between(1, max_batches),
          matches: be_between(1, max_batches * batch_size),
          mismatches: 0,
          mismatches_details: [],
          start_id: be_between(min_id, max_id),
          next_start_id: be_between(min_id, max_id)
        }
        expect(consistency_check_service).to receive(:rand).with(min_id..max_id).and_call_original
        result = consistency_check_service.execute
        expect(result).to match(expected_result)
      end

      it 'calls the ConsistencyCheckService with the expected parameters' do
        expect(consistency_check_service).to receive(:random_start_id).and_return(min_id)

        allow_next_instance_of(Gitlab::Database::ConsistencyChecker) do |instance|
          expect(instance).to receive(:execute).with(start_id: min_id).and_return({
            batches: 2,
            next_start_id: min_id + batch_size,
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
          matches: 10,
          mismatches: 0,
          mismatches_details: [],
          start_id: be_between(min_id, max_id),
          next_start_id: be_between(min_id, max_id)
        }
        result = consistency_check_service.execute
        expect(result).to match(expected_result)
      end

      it 'saves the next_start_id in Redis for he next iteration' do
        expect(consistency_check_service).to receive(:save_next_start_id)
          .with(be_between(min_id, max_id)).and_call_original
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
