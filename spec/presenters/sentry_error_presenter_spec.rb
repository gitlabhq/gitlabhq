# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SentryErrorPresenter do
  let(:error) { build(:error_tracking_sentry_detailed_error) }
  let(:presenter) { described_class.new(error) }

  describe '#frequency' do
    subject { presenter.frequency }

    it 'returns an array of frequency structs' do
      expect(subject).to include(a_kind_of(SentryErrorPresenter::FrequencyStruct))
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

  describe '#project_id' do
    subject { presenter.project_id }

    it 'returns a global ID of the correct type' do
      expect(subject).to eq(Gitlab::GlobalId.build(model_name: 'SentryProject', id: error.project_id).to_s)
    end
  end
end
