# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Components::Usages::Aggregator, :clean_gitlab_redis_shared_state, :freeze_time,
  feature_category: :pipeline_composition do
  let_it_be(:usage_start_date) { Date.today - 30.days }
  let_it_be(:usage_end_date) { Date.today - 1.day }

  let(:usage_model) { Ci::Catalog::Resources::Components::Usage }
  let(:target_scope) { Ci::Catalog::Resource }
  let(:group_by_column) { :catalog_resource_id }
  let(:lease_key) { 'my_lease_key' }

  let(:usage_window) do
    Gitlab::Ci::Components::Usages::Aggregators::Cursor::Window.new(usage_start_date, usage_end_date)
  end

  before_all do
    # First catalog resource: 3 components and 3 usages per component on usage_end_date
    version = create(:ci_catalog_resource_version)
    create_list(:ci_catalog_resource_component, 3, version: version).each do |component|
      (1..3).each do |k|
        create(
          :ci_catalog_resource_component_usage,
          component: component,
          used_date: usage_end_date,
          used_by_project_id: k
        )
      end
    end

    # Create 4 more catalog resources, each with 1-4 components and 0-6 usages
    # per component on different dates before and after usage_end_date
    create_list(:ci_catalog_resource_version, 4).each_with_index do |version, i|
      create_list(:ci_catalog_resource_component, i + 1, version: version).each_with_index do |component, j|
        next unless j > 0

        (1..j * 2).each do |k|
          create(
            :ci_catalog_resource_component_usage,
            component: component,
            used_date: usage_end_date - 3.days + k.days,
            used_by_project_id: k
          )
        end
      end
    end
  end

  describe '#each_batch' do
    shared_examples 'when the runtime limit is not reached' do
      it 'returns the expected result' do
        # We process all catalog resources and advance the cursor
        batched_usage_counts, result = run_new_aggregator_each_batch

        expect(batched_usage_counts).to eq(expected_batched_usage_counts)
        expect(result.total_targets_completed).to eq(target_scope.count)
        expect(result.cursor.attributes).to eq({
          target_id: 0,
          usage_window: usage_window,
          last_used_by_project_id: 0,
          last_usage_count: 0
        })
      end
    end

    shared_examples 'with multiple distinct usage batches' do
      before do
        stub_const("#{described_class}::DISTINCT_USAGE_BATCH_SIZE", 2)
      end

      it_behaves_like 'when the runtime limit is not reached'

      context 'when the runtime limit is reached' do
        before do
          # Sets the aggregator to break after the first iteration on each run
          stub_const("#{described_class}::MAX_RUNTIME", 0)
        end

        it 'returns the expected result for each run' do
          # On 1st run, we get an incomplete usage count for the first catalog resource
          batched_usage_counts, result = run_new_aggregator_each_batch

          expect(batched_usage_counts).to eq([])
          expect(result.total_targets_completed).to eq(0)
          expect(result.cursor.attributes).to eq({
            target_id: target_scope.first.id,
            usage_window: usage_window,
            last_used_by_project_id: 2,
            last_usage_count: 2
          })

          # On 2nd run, we get the complete usage count for the first catalog resource and advance the cursor
          batched_usage_counts, result = run_new_aggregator_each_batch

          expect(batched_usage_counts).to eq([{ target_scope.first => 3 }])
          expect(result.total_targets_completed).to eq(1)
          expect(result.cursor.attributes).to eq({
            target_id: target_scope.first.id + 1,
            usage_window: usage_window,
            last_used_by_project_id: 0,
            last_usage_count: 0
          })

          all_batched_usage_counts = batched_usage_counts + repeat_new_aggregator_each_batch_until_done
          batched_usage_counts_merged = all_batched_usage_counts.flatten.reduce(&:merge)

          expect(batched_usage_counts_merged.length).to eq(5)
          expect(batched_usage_counts_merged).to eq(expected_batched_usage_counts_merged)
        end

        context 'when a target is deleted between runs' do
          it 'returns the expected result for each run' do
            # On 1st run, we get an incomplete usage count for the first catalog resource
            batched_usage_counts, result = run_new_aggregator_each_batch

            expect(batched_usage_counts).to eq([])
            expect(result.total_targets_completed).to eq(0)
            expect(result.cursor.attributes).to eq({
              target_id: target_scope.first.id,
              usage_window: usage_window,
              last_used_by_project_id: 2,
              last_usage_count: 2
            })

            target_scope.first.delete

            all_batched_usage_counts = repeat_new_aggregator_each_batch_until_done
            batched_usage_counts_merged = all_batched_usage_counts.reduce(&:merge)

            expect(batched_usage_counts_merged.length).to eq(4)
            expect(batched_usage_counts_merged).to eq(expected_batched_usage_counts_merged)
          end
        end

        context 'when there are no usage records' do
          it 'returns the expected result' do
            usage_model.delete_all

            all_batched_usage_counts = repeat_new_aggregator_each_batch_until_done
            batched_usage_counts_merged = all_batched_usage_counts.reduce(&:merge)

            expect(batched_usage_counts_merged.length).to eq(5)
            expect(batched_usage_counts_merged).to eq(expected_batched_usage_counts_merged)
          end
        end
      end
    end

    it_behaves_like 'when the runtime limit is not reached'
    it_behaves_like 'with multiple distinct usage batches'

    context 'with multiple target batches' do
      before do
        stub_const("#{described_class}::TARGET_BATCH_SIZE", 3)
      end

      it_behaves_like 'when the runtime limit is not reached'
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
      target_scope: target_scope,
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
    batched_usage_counts = []

    target_scope.each_batch(of: described_class::TARGET_BATCH_SIZE) do |targets|
      usage_counts = usage_model
                       .includes(:catalog_resource)
                       .select('catalog_resource_id, COUNT(DISTINCT used_by_project_id) AS usage_count')
                       .where(used_date: usage_start_date..usage_end_date)
                       .where(group_by_column => targets)
                       .group(:catalog_resource_id)
                       .each_with_object({}) { |r, hash| hash[r.catalog_resource] = r.usage_count }

      batched_usage_counts << targets.index_with { 0 }.merge(usage_counts)
    end

    batched_usage_counts
  end

  def expected_batched_usage_counts_merged
    expected_batched_usage_counts.reduce(&:merge)
  end

  def repeat_new_aggregator_each_batch_until_done
    all_batched_usage_counts = []

    30.times do
      batched_usage_counts, result = run_new_aggregator_each_batch
      all_batched_usage_counts << batched_usage_counts
      break if result.cursor.target_id == 0
    end

    all_batched_usage_counts.flatten
  end
end
