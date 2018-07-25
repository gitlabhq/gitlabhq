require 'spec_helper'

describe TimeHelper do
  describe "#time_interval_in_words" do
    it "returns minutes and seconds" do
      intervals_in_words = {
        60 => "1 minute",
        100 => "1 minute and 40 seconds",
        100.32 => "1 minute and 40 seconds",
        120 => "2 minutes",
        121 => "2 minutes and 1 second",
        3721 => "62 minutes and 1 second",
        0 => "0 seconds"
      }

      intervals_in_words.each do |interval, expectation|
        expect(time_interval_in_words(interval)).to eq(expectation)
      end
    end
  end

  describe "#duration_in_numbers" do
    it "returns minutes and seconds" do
      durations_and_expectations = {
        100 => "01:40",
        121 => "02:01",
        3721 => "01:02:01",
        0 => "00:00",
        42 => "00:42"
      }

      durations_and_expectations.each do |duration, expectation|
        expect(duration_in_numbers(duration)).to eq(expectation)
      end
    end
  end
end
