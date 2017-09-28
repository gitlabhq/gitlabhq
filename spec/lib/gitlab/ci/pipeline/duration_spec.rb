require 'spec_helper'

describe Gitlab::Ci::Pipeline::Duration do
  let(:calculated_duration) { calculate(data) }

  shared_examples 'calculating duration' do
    it do
      expect(calculated_duration).to eq(duration)
    end
  end

  context 'test sample A' do
    let(:data) do
      [[0, 1],
       [1, 2],
       [3, 4],
       [5, 6]]
    end

    let(:duration) { 4 }

    it_behaves_like 'calculating duration'
  end

  context 'test sample B' do
    let(:data) do
      [[0, 1],
       [1, 2],
       [2, 3],
       [3, 4],
       [0, 4]]
    end

    let(:duration) { 4 }

    it_behaves_like 'calculating duration'
  end

  context 'test sample C' do
    let(:data) do
      [[0, 4],
       [2, 6],
       [5, 7],
       [8, 9]]
    end

    let(:duration) { 8 }

    it_behaves_like 'calculating duration'
  end

  context 'test sample D' do
    let(:data) do
      [[0, 1],
       [2, 3],
       [4, 5],
       [6, 7]]
    end

    let(:duration) { 4 }

    it_behaves_like 'calculating duration'
  end

  context 'test sample E' do
    let(:data) do
      [[0, 1],
       [3, 9],
       [3, 4],
       [3, 5],
       [3, 8],
       [4, 5],
       [4, 7],
       [5, 8]]
    end

    let(:duration) { 7 }

    it_behaves_like 'calculating duration'
  end

  context 'test sample F' do
    let(:data) do
      [[1, 3],
       [2, 4],
       [2, 4],
       [2, 4],
       [5, 8]]
    end

    let(:duration) { 6 }

    it_behaves_like 'calculating duration'
  end

  context 'test sample G' do
    let(:data) do
      [[1, 3],
       [2, 4],
       [6, 7]]
    end

    let(:duration) { 4 }

    it_behaves_like 'calculating duration'
  end

  def calculate(data)
    periods = data.shuffle.map do |(first, last)|
      described_class::Period.new(first, last)
    end

    described_class.from_periods(periods.sort_by(&:first))
  end
end
