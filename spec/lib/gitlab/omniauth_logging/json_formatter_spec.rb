# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::OmniauthLogging::JSONFormatter do
  it "generates log in json format" do
    Timecop.freeze(Time.utc(2019, 12, 04, 9, 10, 11, 123456)) do
      expect(subject.call(:info, Time.now, 'omniauth', 'log message'))
        .to eq %Q({"severity":"info","timestamp":"2019-12-04T09:10:11.123Z","pid":#{Process.pid},"progname":"omniauth","message":"log message"}\n)
    end
  end
end
