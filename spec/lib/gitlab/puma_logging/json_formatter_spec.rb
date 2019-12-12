# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::PumaLogging::JSONFormatter do
  it "generate json format with timestamp and pid" do
    Timecop.freeze( Time.utc(2019, 12, 04, 9, 10, 11, 123456)) do
      expect(subject.call('log message')).to eq "{\"timestamp\":\"2019-12-04T09:10:11.123Z\",\"pid\":#{Process.pid},\"message\":\"log message\"}"
    end
  end
end
