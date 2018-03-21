require 'rails_helper'

describe MergeRequestMetricsService do
  let(:metrics) { create(:merge_request).metrics }

  describe '#merge' do
    it 'updates metrics' do
      user = create(:user)
      service = described_class.new(metrics)
      event = double(Event, author_id: user.id, created_at: Time.now)

      service.merge(event)

      expect(metrics.merged_by).to eq(user)
      expect(metrics.merged_at).to eq(event.created_at)
    end
  end

  describe '#close' do
    it 'updates metrics' do
      user = create(:user)
      service = described_class.new(metrics)
      event = double(Event, author_id: user.id, created_at: Time.now)

      service.close(event)

      expect(metrics.latest_closed_by).to eq(user)
      expect(metrics.latest_closed_at).to eq(event.created_at)
    end
  end

  describe '#reopen' do
    it 'updates metrics' do
      service = described_class.new(metrics)

      service.reopen

      expect(metrics.latest_closed_by).to be_nil
      expect(metrics.latest_closed_at).to be_nil
    end
  end
end
