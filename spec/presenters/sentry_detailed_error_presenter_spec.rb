# frozen_string_literal: true

require 'spec_helper'

describe SentryDetailedErrorPresenter do
  let(:error) { build(:detailed_error_tracking_error) }
  let(:presenter) { described_class.new(error) }

  describe '#frequency' do
    subject { presenter.frequency }

    it 'returns an array of frequency structs' do
      expect(subject).to include(a_kind_of(SentryDetailedErrorPresenter::FrequencyStruct))
    end

    it 'converts the times into UTC time objects' do
      time = subject.first.time

      expect(time).to be_a(Time)
      expect(time.strftime('%z')).to eq '+0000'
    end

    it 'returns the correct counts' do
      count = subject.first.count

      expect(count).to eq error.frequency.first[1]
    end
  end
end
