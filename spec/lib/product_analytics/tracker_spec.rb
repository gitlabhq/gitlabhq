# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Tracker do
  it { expect(described_class::URL).to eq('http://localhost/-/sp.js') }
  it { expect(described_class::COLLECTOR_URL).to eq('localhost/-/collector') }
end
