# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::ConsistencyChecker, feature_category: :cell do
  let(:batch_size) { 10 }
  let(:max_batches) { 4 }
  let(:max_runtime) { described_class::MAX_RUNTIME }
  let(:metrics_counter) { Gitlab::Metrics.registry.get(:consistency_checks) }

  subject(:consistency_checker) do
    described_class.new(
      source_model: Namespace,
      target_model: Ci::NamespaceMirror,
      source_columns: %w[id traversal_ids],
      target_columns: %w[namespace_id traversal_ids]
    )
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", batch_size)
    stub_const("#{described_class.name}::MAX_BATCHES", max_batches)
    redis_shared_state_cleanup! # For Prometheus Counters
  end

  after do
    Gitlab::Metrics.reset_registry!
  end

  describe '#over_time_limit?' do
    before do
      allow(consistency_checker).to receive(:start_time).and_return(0)
    end

    it 'returns true only if the running time has exceeded MAX_RUNTIME' do
      allow(consistency_checker).to receive(:monotonic_time).and_return(0, max_runtime - 1, max_runtime + 1)
      expect(consistency_checker.monotonic_time).to eq(0)
      expect(consistency_checker.send(:over_time_limit?)).to eq(false)
      expect(consistency_checker.send(:over_time_limit?)).to eq(true)
    end
  end

  describe '#execute' do
    context 'when empty tables' do
      it 'returns an empty response' do
        expected_result = { matches: 0, mismatches: 0, batches: 0, mismatches_details: [], next_start_id: nil }
        expect(consistency_checker.execute(start_id: 1)).to eq(expected_result)
      end
    end

    context 'when the tables contain matching items' do
      before do
        create_list(:namespace, 50) # This will also create Ci::NameSpaceMirror objects
      end

      it 'does not process more than MAX_BATCHES' do
        max_batches = 3
        stub_const("#{described_class.name}::MAX_BATCHES", max_batches)
        result = consistency_checker.execute(start_id: Namespace.minimum(:id))
        expect(result[:batches]).to eq(max_batches)
        expect(result[:matches]).to eq(max_batches * batch_size)
      end

      it 'doesn not exceed the MAX_RUNTIME' do
        allow(consistency_checker).to receive(:monotonic_time).and_return(0, max_runtime - 1, max_runtime + 1)
        result = consistency_checker.execute(start_id: Namespace.minimum(:id))
        expect(result[:batches]).to eq(1)
        expect(result[:matches]).to eq(1 * batch_size)
      end

      it 'returns the correct number of matches and batches checked' do
        expected_result = {
          next_start_id: Namespace.minimum(:id) + (described_class::MAX_BATCHES * described_class::BATCH_SIZE),
          batches: max_batches,
          matches: max_batches * batch_size,
          mismatches: 0,
          mismatches_details: []
        }
        expect(consistency_checker.execute(start_id: Namespace.minimum(:id))).to eq(expected_result)
      end

      it 'returns the min_id as the next_start_id if the check reaches the last element' do
        expect(Gitlab::Metrics).to receive(:counter).at_most(:once)
          .with(:consistency_checks, "Consistency Check Results")
          .and_call_original

        # Starting from the 5th last element
        start_id = Namespace.all.order(id: :desc).limit(5).pluck(:id).last
        expected_result = {
          next_start_id: Namespace.first.id,
          batches: 1,
          matches: 5,
          mismatches: 0,
          mismatches_details: []
        }
        expect(consistency_checker.execute(start_id: start_id)).to eq(expected_result)

        expect(metrics_counter.get(source_table: "namespaces", result: "mismatch")).to eq(0)
        expect(metrics_counter.get(source_table: "namespaces", result: "match")).to eq(5)
      end
    end

    context 'when some items are missing from the first table' do
      let(:missing_namespace) { Namespace.all.order(:id).limit(2).last }

      before do
        create_list(:namespace, 50) # This will also create Ci::NameSpaceMirror objects
        missing_namespace.delete
      end

      it 'reports the missing elements' do
        expected_result = {
          next_start_id: Namespace.first.id + (described_class::MAX_BATCHES * described_class::BATCH_SIZE),
          batches: max_batches,
          matches: 39,
          mismatches: 1,
          mismatches_details: [{
            id: missing_namespace.id,
            source_table: nil,
            target_table: [missing_namespace.traversal_ids]
          }]
        }
        expect(consistency_checker.execute(start_id: Namespace.first.id)).to eq(expected_result)

        expect(metrics_counter.get(source_table: "namespaces", result: "mismatch")).to eq(1)
        expect(metrics_counter.get(source_table: "namespaces", result: "match")).to eq(39)
      end
    end

    context 'when some items are missing from the second table' do
      let(:missing_ci_namespace_mirror) { Ci::NamespaceMirror.all.order(:id).limit(2).last }

      before do
        create_list(:namespace, 50) # This will also create Ci::NameSpaceMirror objects
        missing_ci_namespace_mirror.delete
      end

      it 'reports the missing elements' do
        expected_result = {
          next_start_id: Namespace.first.id + (described_class::MAX_BATCHES * described_class::BATCH_SIZE),
          batches: 4,
          matches: 39,
          mismatches: 1,
          mismatches_details: [{
            id: missing_ci_namespace_mirror.namespace_id,
            source_table: [missing_ci_namespace_mirror.traversal_ids],
            target_table: nil
          }]
        }
        expect(consistency_checker.execute(start_id: Namespace.first.id)).to eq(expected_result)

        expect(metrics_counter.get(source_table: "namespaces", result: "mismatch")).to eq(1)
        expect(metrics_counter.get(source_table: "namespaces", result: "match")).to eq(39)
      end
    end

    context 'when elements are different between the two tables' do
      let(:different_namespaces) { Namespace.order(:id).limit(max_batches * batch_size).sample(3).sort_by(&:id) }

      before do
        create_list(:namespace, 50) # This will also create Ci::NameSpaceMirror objects

        different_namespaces.each do |namespace|
          namespace.update_attribute(:traversal_ids, [])
        end
      end

      it 'reports the difference between the two tables' do
        expected_result = {
          next_start_id: Namespace.first.id + (described_class::MAX_BATCHES * described_class::BATCH_SIZE),
          batches: 4,
          matches: 37,
          mismatches: 3,
          mismatches_details: different_namespaces.map do |namespace|
            {
              id: namespace.id,
              source_table: [[]],
              target_table: [[namespace.id]] # old traversal_ids of the namespace
            }
          end
        }
        expect(consistency_checker.execute(start_id: Namespace.first.id)).to eq(expected_result)

        expect(metrics_counter.get(source_table: "namespaces", result: "mismatch")).to eq(3)
        expect(metrics_counter.get(source_table: "namespaces", result: "match")).to eq(37)
      end
    end
  end
end
