# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::DatabaseMetric, feature_category: :service_ping do
  let(:database_metric_class) { Class.new(described_class) }

  subject do
    database_metric_class.tap do |metric_class|
      metric_class.relation { Issue }
      metric_class.operation :count
      metric_class.start { Issue.minimum(:id) }
      metric_class.finish { Issue.maximum(:id) }
    end.new(time_frame: 'all')
  end

  describe '#value' do
    let_it_be(:issue_1) { create(:issue) }
    let_it_be(:issue_2) { create(:issue) }
    let_it_be(:issue_3) { create(:issue) }
    let_it_be(:issues) { Issue.all }

    before do
      allow(Issue.connection).to receive(:transaction_open?).and_return(false)
    end

    it 'calculates a correct result' do
      expect(subject.value).to eq(3)
    end

    it 'does not cache the result of start and finish', :request_store, :use_clean_rails_redis_caching do
      expect(Gitlab::Cache).not_to receive(:fetch_once)
      expect(subject).to receive(:count).with(any_args, hash_including(start: issues.min_by(&:id).id, finish: issues.max_by(&:id).id)).and_call_original

      subject.value

      expect(Rails.cache.read('metric_instrumentation/special_issue_count_minimum_id')).to eq(nil)
      expect(Rails.cache.read('metric_instrumentation/special_issue_count_maximum_id')).to eq(nil)
    end

    context 'with metric options specified with custom batch_size' do
      subject do
        database_metric_class.tap do |metric_class|
          metric_class.relation { Issue }
          metric_class.operation :count
          metric_class.start { Issue.minimum(:id) }
          metric_class.finish { Issue.maximum(:id) }
          metric_class.metric_options { { batch_size: 12345 } }
        end.new(time_frame: 'all')
      end

      it 'calls metric with customized batch_size' do
        expect(subject).to receive(:count).with(any_args, hash_including(batch_size: 12345, start: issues.min_by(&:id).id, finish: issues.max_by(&:id).id)).and_call_original

        subject.value
      end

      it 'calculates a correct result' do
        expect(subject.value).to eq(3)
      end
    end

    context 'with start and finish not called' do
      subject do
        database_metric_class.tap do |metric_class|
          metric_class.relation { Issue }
          metric_class.operation :count
        end.new(time_frame: 'all')
      end

      it 'calculates a correct result' do
        expect(subject.value).to eq(3)
      end
    end

    context 'with availability defined' do
      subject do
        database_metric_class.tap do |metric_class|
          metric_class.relation { Issue }
          metric_class.operation :count
          metric_class.available? { false }
        end.new(time_frame: 'all')
      end

      it 'responds to #available? properly' do
        expect(subject.available?).to eq(false)
      end
    end

    context 'with availability not defined' do
      subject do
        database_metric_class do
          relation { Issue }
          operation :count
        end.new(time_frame: 'all')
      end

      it 'responds to #available? properly' do
        expect(subject.available?).to eq(true)
      end
    end

    context 'with cache_start_and_finish_as called' do
      subject do
        database_metric_class.tap do |metric_class|
          metric_class.relation { Issue }
          metric_class.operation :count
          metric_class.start { Issue.minimum(:id) }
          metric_class.finish { Issue.maximum(:id) }
          metric_class.cache_start_and_finish_as :special_issue_count
        end.new(time_frame: 'all')
      end

      it 'caches using the key name passed', :request_store, :use_clean_rails_redis_caching do
        expect(Gitlab::Cache).to receive(:fetch_once).with('metric_instrumentation/special_issue_count_minimum_id', any_args).and_call_original
        expect(Gitlab::Cache).to receive(:fetch_once).with('metric_instrumentation/special_issue_count_maximum_id', any_args).and_call_original
        expect(subject).to receive(:count).with(any_args, hash_including(start: issues.min_by(&:id).id, finish: issues.max_by(&:id).id)).and_call_original

        subject.value

        expect(Rails.cache.read('metric_instrumentation/special_issue_count_minimum_id')).to eq(issues.min_by(&:id).id)
        expect(Rails.cache.read('metric_instrumentation/special_issue_count_maximum_id')).to eq(issues.max_by(&:id).id)
      end
    end

    context 'with estimate_batch_distinct_count' do
      subject do
        database_metric_class.tap do |metric_class|
          metric_class.relation { Issue }
          metric_class.operation(:estimate_batch_distinct_count)
          metric_class.start { Issue.minimum(:id) }
          metric_class.finish { Issue.maximum(:id) }
        end.new(time_frame: 'all')
      end

      it 'calculates a correct result', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/349762' do
        expect(subject.value).to be_within(Gitlab::Database::PostgresHll::BatchDistinctCounter::ERROR_RATE).percent_of(3)
      end

      context 'with block passed to operation' do
        let(:buckets) { double('Buckets').as_null_object }

        subject do
          database_metric_class.tap do |metric_class|
            metric_class.relation { Issue }
            metric_class.operation(:estimate_batch_distinct_count) do |result|
              result.foo
            end
            metric_class.start { Issue.minimum(:id) }
            metric_class.finish { Issue.maximum(:id) }
          end.new(time_frame: 'all')
        end

        before do
          allow(Gitlab::Database::PostgresHll::Buckets).to receive(:new).and_return(buckets)
        end

        it 'calls the block passing HLL buckets as an argument' do
          expect(buckets).to receive(:foo)

          subject.value
        end
      end
    end

    context 'with custom timestamp column' do
      subject do
        database_metric_class.tap do |metric_class|
          metric_class.relation { Issue }
          metric_class.operation :count
          metric_class.timestamp_column :last_edited_at
        end.new(time_frame: '28d')
      end

      it 'calculates a correct result' do
        create(:issue, last_edited_at: 40.days.ago)
        create(:issue, last_edited_at: 5.days.ago)

        expect(subject.value).to eq(1)
      end
    end

    context 'with default timestamp column' do
      subject do
        database_metric_class.tap do |metric_class|
          metric_class.relation { Issue }
          metric_class.operation :count
        end.new(time_frame: '28d')
      end

      it 'calculates a correct result' do
        create(:issue, created_at: 40.days.ago)
        create(:issue, created_at: 5.days.ago)

        expect(subject.value).to eq(1)
      end
    end

    context 'with 7 days time frame' do
      subject do
        database_metric_class.tap do |metric_class|
          metric_class.relation { Issue }
          metric_class.operation :count
        end.new(time_frame: '7d')
      end

      it 'calculates a correct result' do
        create(:issue, created_at: 10.days.ago)
        create(:issue, created_at: 5.days.ago)

        expect(subject.value).to eq(1)
      end
    end

    context 'with additional parameters passed via options' do
      subject do
        database_metric_class.tap do |metric_class|
          metric_class.relation ->(options) { Issue.where(confidential: options[:confidential]) }
          metric_class.operation :count
        end.new(time_frame: '28d', options: { confidential: true })
      end

      it 'calculates a correct result' do
        create(:issue, created_at: 5.days.ago, confidential: true)
        create(:issue, created_at: 5.days.ago, confidential: false)

        expect(subject.value).to eq(1)
      end
    end
  end

  context 'with unimplemented operation method used' do
    subject do
      database_metric_class.tap do |metric_class|
        metric_class.relation { Issue }
        metric_class.operation :invalid_operation
      end.new(time_frame: 'all')
    end

    it 'raises an error' do
      expect { subject }.to raise_error(described_class::UnimplementedOperationError)
    end
  end
end
