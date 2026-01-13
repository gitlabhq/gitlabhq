# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::RecordCountMonitor, feature_category: :database do
  describe '.subscribe' do
    before do
      described_class.instance_variable_set(:@subscribed, nil)
    end

    it 'subscribes to sql.active_record notifications' do
      expect(ActiveSupport::Notifications).to receive(:subscribe).with('sql.active_record')

      described_class.subscribe
    end

    it 'only subscribes once' do
      expect(ActiveSupport::Notifications).to receive(:subscribe).once

      described_class.subscribe
      described_class.subscribe
    end
  end

  describe '.warn_large_result_set' do
    before do
      allow(Gitlab::AppLogger).to receive(:warn)
    end

    it 'logs warning with row count and SQL' do
      described_class.warn_large_result_set({ row_count: 5000, sql: 'SELECT * FROM users' })

      expect(Gitlab::AppLogger).to have_received(:warn)
        .with("Query fetched 5000 rows (threshold: 1000)\nSQL: SELECT * FROM users")
    end

    it 'logs warning without SQL when not present' do
      described_class.warn_large_result_set({ row_count: 5000 })

      expect(Gitlab::AppLogger).to have_received(:warn)
        .with("Query fetched 5000 rows (threshold: 1000)")
    end
  end
end
