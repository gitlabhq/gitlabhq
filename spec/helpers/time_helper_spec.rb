# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeHelper do
  describe "#time_interval_in_words" do
    it "returns minutes and seconds" do
      intervals_in_words = {
        60 => "1 minute",
        100 => "1 minute and 40 seconds",
        100.32 => "1 minute and 40 seconds",
        120 => "2 minutes",
        121 => "2 minutes and 1 second",
        3721 => "1 hour, 2 minutes, and 1 second",
        0 => "0 seconds"
      }

      intervals_in_words.each do |interval, expectation|
        expect(time_interval_in_words(interval)).to eq(expectation)
      end
    end
  end

  describe "#duration_in_numbers" do
    using RSpec::Parameterized::TableSyntax

    where(:duration, :formatted_string) do
      0                              | "00:00"
      1.second                       | "00:01"
      42.seconds                     | "00:42"
      (2.minutes + 1.second)           | "02:01"
      (3.hours + 2.minutes + 1.second) | "03:02:01"
      30.hours | "30:00:00"
    end

    with_them do
      it { expect(duration_in_numbers(duration)).to eq formatted_string }
    end
  end

  describe "#time_in_milliseconds" do
    it "returns the time in milliseconds" do
      freeze_time do
        time = (Time.now.to_f * 1000).to_i

        expect(time_in_milliseconds).to eq time
      end
    end
  end
end
