require 'spec_helper'

describe HistoricalData do
  before do
    (1..12).each do |i|
      HistoricalData.create!(date: Date.new(2014, i, 1), active_user_count: i * 100)
    end
  end

  describe ".during" do
    it "returns the historical data during the given period" do
      expect(HistoricalData.during(Date.new(2014, 1, 1)..Date.new(2014, 12, 31)).average(:active_user_count)).to eq(650)
    end
  end

  describe ".at" do
    it "returns the historical data at the given date" do
      expect(HistoricalData.at(Date.new(2014, 8, 1)).active_user_count).to eq(800)
    end
  end

  describe ".track!" do
    before do
      allow(User).to receive(:active).and_return([1,2,3,4,5])
    end

    it "creates a new historical data record" do
      HistoricalData.track!

      data = HistoricalData.last
      expect(data.date).to eq(Date.today)
      expect(data.active_user_count).to eq(5)
    end
  end
end
