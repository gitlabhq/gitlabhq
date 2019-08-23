# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Patch::ChronicDuration do
  subject { ChronicDuration.parse('1mo') }

  it 'uses default conversions' do
    expect(subject).to eq(2_592_000)
  end

  context 'with custom conversions' do
    before do
      ChronicDuration.hours_per_day = 8
      ChronicDuration.days_per_week = 5
    end

    after do
      ChronicDuration.hours_per_day = 24
      ChronicDuration.days_per_week = 7
    end

    it 'uses custom conversions' do
      expect(subject).to eq(576_000)
    end
  end
end
