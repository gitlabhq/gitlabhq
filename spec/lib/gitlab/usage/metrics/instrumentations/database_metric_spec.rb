# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::DatabaseMetric do
  subject do
    described_class.tap do |m|
      m.relation { Issue }
      m.operation :count
      m.start { m.relation.minimum(:id) }
      m.finish { m.relation.maximum(:id) }
    end.new(time_frame: 'all')
  end

  describe '#value' do
    let_it_be(:issue_1) { create(:issue) }
    let_it_be(:issue_2) { create(:issue) }
    let_it_be(:issue_3) { create(:issue) }
    let_it_be(:issues) { Issue.all }

    before do
      allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
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

    context 'with start and finish not called' do
      subject do
        described_class.tap do |m|
          m.relation { Issue }
          m.operation :count
        end.new(time_frame: 'all')
      end

      it 'calculates a correct result' do
        expect(subject.value).to eq(3)
      end
    end

    context 'with cache_start_and_finish_as called' do
      subject do
        described_class.tap do |m|
          m.relation { Issue }
          m.operation :count
          m.start { m.relation.minimum(:id) }
          m.finish { m.relation.maximum(:id) }
          m.cache_start_and_finish_as :special_issue_count
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
  end
end
