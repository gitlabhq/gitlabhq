# frozen_string_literal: true
require 'fast_spec_helper'

RSpec.describe Gitlab::Analytics::DateFiller do
  let(:default_value) { 0 }
  let(:formatter) { Gitlab::Analytics::DateFiller::DEFAULT_DATE_FORMATTER }

  subject(:filler_result) do
    described_class.new(
      data,
      from: from,
      to: to,
      period: period,
      default_value: default_value,
      date_formatter: formatter
    ).fill.to_a
  end

  context 'when unknown period is given' do
    it 'raises unknown period error' do
      input = { 3.days.ago.to_date => 10, Date.today => 5 }

      expect do
        described_class.new(input, from: 4.days.ago, to: Date.today, period: :unknown).fill
      end.to raise_error(/Unknown period given/)
    end
  end

  context 'when period=:day' do
    let(:from) { Date.new(2021, 5, 25) }
    let(:to) { Date.new(2021, 6, 5) }
    let(:period) { :day }

    let(:expected_result) do
      {
        Date.new(2021, 5, 25) => 1,
        Date.new(2021, 5, 26) => default_value,
        Date.new(2021, 5, 27) => default_value,
        Date.new(2021, 5, 28) => default_value,
        Date.new(2021, 5, 29) => default_value,
        Date.new(2021, 5, 30) => default_value,
        Date.new(2021, 5, 31) => default_value,
        Date.new(2021, 6, 1) => default_value,
        Date.new(2021, 6, 2) => default_value,
        Date.new(2021, 6, 3) => 10,
        Date.new(2021, 6, 4) => default_value,
        Date.new(2021, 6, 5) => default_value
      }
    end

    let(:data) do
      {
        Date.new(2021, 6, 3) => 10, # deliberatly not sorted
        Date.new(2021, 5, 27) => nil,
        Date.new(2021, 5, 25) => 1
      }
    end

    it { is_expected.to eq(expected_result.to_a) }

    context 'when a custom default value is given' do
      let(:default_value) { 'MISSING' }

      it do
        is_expected.to eq(expected_result.to_a)
      end
    end

    context 'when a custom date formatter is given' do
      let(:formatter) { ->(date) { date.to_s } }

      it do
        expected_result.transform_keys!(&:to_s)

        is_expected.to eq(expected_result.to_a)
      end
    end

    context 'when the data contains dates outside of the requested period' do
      let(:date_outside_of_the_period) { Date.new(2022, 6, 1) }

      before do
        data[date_outside_of_the_period] = 5
      end

      it 'ignores the data outside of the requested period' do
        is_expected.to eq(expected_result.to_a)
      end
    end
  end

  context 'when period=:week' do
    let(:from) { Date.new(2021, 5, 16) }
    let(:to) { Date.new(2021, 6, 7) }
    let(:period) { :week }
    let(:data) do
      {
        Date.new(2021, 5, 24) => nil,
        Date.new(2021, 6, 7) => 10
      }
    end

    let(:expected_result) do
      {
        Date.new(2021, 5, 10) => 0,
        Date.new(2021, 5, 17) => 0,
        Date.new(2021, 5, 24) => 0,
        Date.new(2021, 5, 31) => 0,
        Date.new(2021, 6, 7) => 10
      }
    end

    it do
      is_expected.to eq(expected_result.to_a)
    end
  end

  context 'when period=:month' do
    let(:from) { Date.new(2021, 5, 1) }
    let(:to) { Date.new(2021, 7, 1) }
    let(:period) { :month }
    let(:data) do
      {
        Date.new(2021, 5, 1) => 100
      }
    end

    let(:expected_result) do
      {
        Date.new(2021, 5, 1) => 100,
        Date.new(2021, 6, 1) => 0,
        Date.new(2021, 7, 1) => 0
      }
    end

    it do
      is_expected.to eq(expected_result.to_a)
    end
  end
end
