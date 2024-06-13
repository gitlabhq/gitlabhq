# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Components::Usages::Aggregator, :clean_gitlab_redis_shared_state, :freeze_time,
  feature_category: :pipeline_composition do
  let_it_be(:usage_start_date) { Date.today - 30.days }
  let_it_be(:usage_end_date) { Date.today - 1.day }

  let_it_be(:resources) { create_list(:ci_catalog_resource, 5).sort_by(&:id) }
  let_it_be(:expected_usage_counts) { resources.zip([3, 17, 0, 1, 26]).to_h }

  let(:usage_model) { Ci::Catalog::Resources::Components::Usage }
  let(:target_model) { Ci::Catalog::Resource }
  let(:group_by_column) { :catalog_resource_id }
  let(:lease_key) { 'my_lease_key' }

  let(:usage_window) do
    Gitlab::Ci::Components::Usages::Aggregators::Cursor::Window.new(usage_start_date, usage_end_date)
  end

  before_all do
    # Set up each resource with 1-5 versions, 1-5 components per version, and the expected usages per component
    expected_usage_counts.each_with_index do |(resource, usage_count), i|
      create_list(:ci_catalog_resource_version, i + 1, catalog_resource: resource).each do |version|
        (1..i + 1).each do |j|
          component = create(:ci_catalog_resource_component, version: version, name: "component#{j}")

          (1..usage_count).each do |k|
            # Inside the usage window
            create(:ci_catalog_resource_component_usage,
              component: component, used_date: usage_start_date, used_by_project_id: k)
            # Outside the usage window
            create(:ci_catalog_resource_component_usage,
              component: component, used_date: usage_start_date - k.days, used_by_project_id: k)
          end
        end
      end
    end
  end

  describe '#each_batch' do
    shared_examples 'when the aggregator is not interrupted' do
      it 'returns the expected result' do
        # We process all catalog resources and advance the cursor
        batched_usage_counts, result = run_new_aggregator_each_batch

        expect(batched_usage_counts).to eq(expected_batched_usage_counts)
        expect(result.total_targets_completed).to eq(target_model.count)
        expect(result.cursor_attributes).to eq({
          target_id: 0,
          usage_window: usage_window.to_h,
          last_used_by_project_id: 0,
          last_usage_count: 0,
          max_target_id: target_model.maximum(:id).to_i
        })
      end
    end

    shared_examples 'with multiple distinct usage batches' do
      before do
        stub_const("#{described_class}::DISTINCT_USAGE_BATCH_SIZE", 2)
      end

      it_behaves_like 'when the aggregator is not interrupted'

      context 'when the aggregator is interrupted' do
        before do
          # Sets the aggregator to break after the first iteration on each run
          stub_const("#{described_class}::MAX_RUNTIME", 0)
        end

        it 'returns the expected result for each run' do
          # On 1st run, we get an incomplete usage count for the first catalog resource
          batched_usage_counts, result = run_new_aggregator_each_batch

          expect(batched_usage_counts).to eq([])
          expect(result.total_targets_completed).to eq(0)
          expect(result.cursor_attributes).to eq({
            target_id: target_model.first.id,
            usage_window: usage_window.to_h,
            last_used_by_project_id: 2,
            last_usage_count: 2,
            max_target_id: target_model.maximum(:id).to_i
          })

          # On 2nd run, we get the complete usage count for the first catalog resource and advance the cursor
          batched_usage_counts, result = run_new_aggregator_each_batch

          expect(batched_usage_counts).to eq([{ target_model.first => 3 }])
          expect(result.total_targets_completed).to eq(1)
          expect(result.cursor_attributes).to eq({
            target_id: target_model.first.id + 1,
            usage_window: usage_window.to_h,
            last_used_by_project_id: 0,
            last_usage_count: 0,
            max_target_id: target_model.maximum(:id).to_i
          })

          all_batched_usage_counts = batched_usage_counts + repeat_new_aggregator_each_batch_until_done
          batched_usage_counts_merged = all_batched_usage_counts.flatten.reduce(&:merge)

          expect(batched_usage_counts_merged.length).to eq(5)
          expect(batched_usage_counts_merged).to eq(expected_usage_counts)
        end

        context 'when a target is deleted between runs' do
          it 'returns the expected result for each run' do
            # On 1st run, we get an incomplete usage count for the first catalog resource
            batched_usage_counts, result = run_new_aggregator_each_batch

            expect(batched_usage_counts).to eq([])
            expect(result.total_targets_completed).to eq(0)
            expect(result.cursor_attributes).to eq({
              target_id: target_model.first.id,
              usage_window: usage_window.to_h,
              last_used_by_project_id: 2,
              last_usage_count: 2,
              max_target_id: target_model.maximum(:id).to_i
            })

            target_model.first.delete

            all_batched_usage_counts = repeat_new_aggregator_each_batch_until_done
            batched_usage_counts_merged = all_batched_usage_counts.reduce(&:merge)

            expect(batched_usage_counts_merged.length).to eq(4)
            expect(batched_usage_counts_merged).to eq(expected_usage_counts.except(resources.first))
          end
        end

        context 'when there are no usage records' do
          it 'returns the expected result' do
            usage_model.delete_all

            all_batched_usage_counts = repeat_new_aggregator_each_batch_until_done
            batched_usage_counts_merged = all_batched_usage_counts.reduce(&:merge)

            expect(batched_usage_counts_merged.length).to eq(5)
            expect(batched_usage_counts_merged).to eq(expected_usage_counts.transform_values { 0 })
          end
        end
      end
    end

    it_behaves_like 'when the aggregator is not interrupted'
    it_behaves_like 'with multiple distinct usage batches'

    context 'with multiple target batches' do
      before do
        stub_const("#{described_class}::TARGET_BATCH_SIZE", 3)
      end

      it_behaves_like 'when the aggregator is not interrupted'
      it_behaves_like 'with multiple distinct usage batches'
    end

    it 'prevents parallel processing with an exclusive lease guard' do
      lease = Gitlab::ExclusiveLease.new(lease_key, timeout: 1.minute).tap(&:try_obtain)
      result = run_new_aggregator_each_batch.last

      expect(result).to be_nil
      lease.cancel
    end
  end

  private

  def run_new_aggregator_each_batch
    aggregator = described_class.new(
      target_model: target_model,
      group_by_column: group_by_column,
      usage_start_date: usage_start_date,
      usage_end_date: usage_end_date,
      lease_key: lease_key
    )

    batched_usage_counts = []

    result = aggregator.each_batch do |usage_counts|
      batched_usage_counts << usage_counts
    end

    [batched_usage_counts, result]
  end

  def expected_batched_usage_counts
    resources.each_slice(described_class::TARGET_BATCH_SIZE).map do |batch|
      expected_usage_counts.slice(*batch)
    end
  end

  def repeat_new_aggregator_each_batch_until_done
    all_batched_usage_counts = []

    30.times do
      batched_usage_counts, result = run_new_aggregator_each_batch
      all_batched_usage_counts << batched_usage_counts
      break if result.cursor_attributes[:target_id] == 0
    end

    all_batched_usage_counts.flatten
  end
end
