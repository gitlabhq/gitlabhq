require 'spec_helper'

describe TimeHelper do
  describe "#time_interval_in_words" do
    it "returns minutes and seconds" do
      intervals_in_words = {
        100 => "1 minute 40 seconds",
        121 => "2 minutes 1 second",
        3721 => "62 minutes 1 second",
        0 => "0 seconds"
      }

      intervals_in_words.each do |interval, expectation|
        expect(time_interval_in_words(interval)).to eq(expectation)
      end
    end
  end

  describe "#duration_in_numbers" do
    it "returns minutes and seconds" do
      duration_in_numbers = {
        [100, 0] => "01:40",
        [121, 0] => "02:01",
        [3721, 0] => "01:02:01",
        [0, 0] => "00:00",
        [nil, Time.now.to_i - 42] => "00:42"
      }

      duration_in_numbers.each do |interval, expectation|
        expect(duration_in_numbers(*interval)).to eq(expectation)
      end
    end
  end
end
