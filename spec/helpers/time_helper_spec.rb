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

  describe "#time_in_milliseconds" do
    it "returns the time in milliseconds" do
      freeze_time do
        time = (Time.now.to_f * 1000).to_i

        expect(time_in_milliseconds).to eq time
      end
    end
  end
end
