# frozen_string_literal: true

require 'spec_helper'

describe UsageCounters do
  let!(:usage_counters) { create(:usage_counters) }

  describe 'maximum number of records' do
    it 'allows for one single record to be created' do
      expect do
        described_class.create!
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: There can only be one usage counters record per instance')
    end
  end

  describe '#totals' do
    subject { usage_counters.totals }

    it 'returns counters' do
      is_expected.to include(web_ide_commits: 0)
    end
  end

  describe '#increment_counters' do
    it 'increments specified counters by 1' do
      expect do
        usage_counters.increment_counters(:web_ide_commits)
      end.to change { usage_counters.reload.web_ide_commits }.from(0).to(1)
    end
  end
end
