# frozen_string_literal: true

RSpec.shared_examples 'within_timeframe scope' do
  describe '.within_timeframe' do
    it 'returns resources with start_date and/or end_date between timeframe' do
      resources = described_class.within_timeframe(now + 2.days, now + 3.days)

      expect(resources).to match_array([resource_2, resource_4])
    end

    it 'returns resources which starts before the timeframe' do
      resources = described_class.within_timeframe(now, now + 1.day)

      expect(resources).to match_array([resource_1, resource_3, resource_4])
    end

    it 'returns resources which ends after the timeframe' do
      resources = described_class.within_timeframe(now + 3.days, now + 5.days)

      expect(resources).to match_array([resource_2, resource_4])
    end
  end
end
