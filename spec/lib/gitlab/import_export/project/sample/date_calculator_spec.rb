# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::Sample::DateCalculator do
  describe '#closest date to average' do
    subject { described_class.new(dates).closest_date_to_average }

    context 'when dates are empty' do
      let(:dates) { [] }

      it { is_expected.to be_nil }
    end

    context 'when dates are not empty' do
      let(:dates) { [nil, '2020-01-01 00:00:00 +0000', '2021-01-01 00:00:00 +0000', nil, '2022-01-01 23:59:59 +0000'] }

      it { is_expected.to eq(Time.zone.parse('2021-01-01 00:00:00 +0000')) }
    end
  end

  describe '#calculate_by_closest_date_to_average' do
    let(:calculator) { described_class.new([]) }
    let(:date) { Time.current }

    subject { calculator.calculate_by_closest_date_to_average(date) }

    context 'when average date is nil' do
      before do
        allow(calculator).to receive(:closest_date_to_average).and_return(nil)
      end

      it { is_expected.to eq(date) }
    end

    context 'when average date is in the past' do
      before do
        allow(calculator).to receive(:closest_date_to_average).and_return(date - 365.days)
        allow(Time).to receive(:current).and_return(date)
      end

      it { is_expected.to eq(date + 365.days) }
    end

    context 'when average date is in the future' do
      before do
        allow(calculator).to receive(:closest_date_to_average).and_return(date + 10.days)
      end

      it { is_expected.to eq(date) }
    end
  end
end
