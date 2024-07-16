# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::AggregateLast30DayUsageService, :clean_gitlab_redis_shared_state, :freeze_time,
  feature_category: :pipeline_composition do
  let_it_be(:usage_start_date) { Date.today - described_class::WINDOW_LENGTH }
  let_it_be(:usage_end_date) { Date.today - 1.day }
  let_it_be(:initial_usage_count_updated_at) { usage_end_date.to_time }

  let_it_be(:resources) { create_list(:ci_catalog_resource, 4).sort_by(&:id) }
  let_it_be(:expected_ordered_usage_counts) { [3, 1, 0, 15] }

  let(:expected_cursor_attributes) do
    {
      target_id: 0,
      usage_window: usage_window_hash,
      last_used_by_project_id: 0,
      last_usage_count: 0,
      max_target_id: Ci::Catalog::Resource.maximum(:id).to_i
    }
  end

  let(:usage_window_hash) { { start_date: usage_start_date, end_date: usage_end_date } }
  let(:lease_key) { described_class.name }
  let(:service) { described_class.new }

  before_all do
    # Set up each resource with 1-4 versions, 1-4 components per version, and the expected usages per component
    expected_ordered_usage_counts.each_with_index do |usage_count, i|
      resource = resources[i]

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

    Ci::Catalog::Resource.update_all(last_30_day_usage_count_updated_at: initial_usage_count_updated_at)
  end

  describe '#execute' do
    context 'when the aggregator is not interrupted' do
      shared_examples 'aggregates usage data for all catalog resources' do
        it 'returns a success response' do
          response = service.execute

          expect(response).to be_success
          expect(response.payload).to eq({
            total_targets_completed: 4,
            cursor_attributes: expected_cursor_attributes
          })
        end
      end

      it_behaves_like 'aggregates usage data for all catalog resources'

      it 'calls BulkUpdate once and updates usage counts for all catalog resources' do
        expect(Gitlab::Database::BulkUpdate).to receive(:execute).once.and_call_original

        service.execute

        expect(ordered_usage_counts).to eq(expected_ordered_usage_counts)
        expect(ordered_usage_counts_updated_at).to match_array([Time.current] * 4)
      end

      context 'when there are two batches of usage counts' do
        before do
          stub_const('Gitlab::Ci::Components::Usages::Aggregator::TARGET_BATCH_SIZE', 2)
        end

        it_behaves_like 'aggregates usage data for all catalog resources'

        it 'calls BulkUpdate twice and updates usage counts for all catalog resources' do
          expect(Gitlab::Database::BulkUpdate).to receive(:execute).twice.and_call_original

          service.execute

          expect(ordered_usage_counts).to eq(expected_ordered_usage_counts)
          expect(ordered_usage_counts_updated_at).to match_array([Time.current] * 4)
        end
      end

      context 'when some catalog resources have already been processed today' do
        before_all do
          resources.first(2).each do |resource|
            resource.update!(last_30_day_usage_count_updated_at: Date.today.to_time)
          end
        end

        # The cursor has not advanced so it still processes all targets
        it_behaves_like 'aggregates usage data for all catalog resources'

        it 'calls BulkUpdate once and updates usage counts for all catalog resources' do
          expect(Gitlab::Database::BulkUpdate).to receive(:execute).once.and_call_original

          service.execute

          expect(ordered_usage_counts).to eq(expected_ordered_usage_counts)
          expect(ordered_usage_counts_updated_at).to match_array([Time.current] * 4)
        end
      end

      context 'when all catalog resources have already been processed today' do
        before_all do
          Ci::Catalog::Resource.update_all(last_30_day_usage_count_updated_at: Date.today.to_time)
        end

        it 'does not aggregate usage data' do
          expect(Gitlab::Ci::Components::Usages::Aggregator).not_to receive(:new)

          response = service.execute

          expect(response).to be_success
          expect(response.message).to eq("Processing complete for #{Date.today}")
          expect(response.payload).to eq({})
        end

        context 'when a new catalog resource is added today' do
          it 'does not aggregate usage data' do
            create(:ci_catalog_resource)
            expect(Gitlab::Ci::Components::Usages::Aggregator).not_to receive(:new)

            response = service.execute

            expect(response).to be_success
            expect(response.message).to eq("Processing complete for #{Date.today}")
            expect(response.payload).to eq({})
          end
        end
      end
    end

    context 'when the aggregator is interrupted' do
      before do
        # Sets the aggregator to break after the first iteration on each run
        stub_const('Gitlab::Ci::Components::Usages::Aggregator::MAX_RUNTIME', 0)
        stub_const('Gitlab::Ci::Components::Usages::Aggregator::DISTINCT_USAGE_BATCH_SIZE', 2)
      end

      it 'updates the expected usage counts for each run' do
        # On 1st run, we get an incomplete usage count for the first catalog resource so it is not saved
        expect { service.execute }
          .to not_change { ordered_usage_counts }
          .and not_change { ordered_usage_counts_updated_at }

        # On 2nd run, we get the complete usage count for the first catalog resource and save it
        service.execute

        expect(ordered_usage_counts).to eq([expected_ordered_usage_counts.first, 0, 0, 0])
        expect(ordered_usage_counts_updated_at).to eq([Time.current, [initial_usage_count_updated_at] * 3].flatten)

        # Execute service repeatedly until done
        30.times do
          response = service.execute
          break if response.payload[:cursor_attributes][:target_id] == 0
        end

        expect(ordered_usage_counts).to eq(expected_ordered_usage_counts)
        expect(ordered_usage_counts_updated_at).to match_array([Time.current] * 4)
      end
    end

    context 'when another instance is running with the same lease key' do
      it 'returns a success response with the lease key' do
        lease = Gitlab::ExclusiveLease.new(lease_key, timeout: 1.minute).tap(&:try_obtain)
        response = service.execute

        expect(response).to be_success
        expect(response.message).to eq('Lease taken')
        expect(response.payload).to eq({ lease_key: lease_key })
        lease.cancel
      end
    end
  end

  private

  def ordered_usage_counts
    Ci::Catalog::Resource.order(:id).pluck(:last_30_day_usage_count)
  end

  def ordered_usage_counts_updated_at
    Ci::Catalog::Resource.order(:id).pluck(:last_30_day_usage_count_updated_at)
  end
end
