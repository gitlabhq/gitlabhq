# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::MarkerRange do
  subject(:marker_range) { described_class.new(first, last, mode: mode) }

  let(:first) { 1 }
  let(:last) { 10 }
  let(:mode) { nil }

  it { is_expected.to eq(first..last) }

  it 'behaves like a Range' do
    is_expected.to be_kind_of(Range)
  end

  describe '#mode' do
    subject { marker_range.mode }

    it { is_expected.to be_nil }

    context 'when mode is provided' do
      let(:mode) { :deletion }

      it { is_expected.to eq(mode) }
    end
  end

  describe '#to_range' do
    subject { marker_range.to_range }

    it { is_expected.to eq(first..last) }

    context 'when mode is provided' do
      let(:mode) { :deletion }

      it 'is omitted during transformation' do
        is_expected.not_to respond_to(:mode)
      end
    end
  end

  describe '.from_range' do
    subject { described_class.from_range(range) }

    let(:range) { 1..3 }

    it 'converts Range to MarkerRange object' do
      is_expected.to be_a(described_class)
    end

    it 'keeps correct range' do
      is_expected.to eq(range)
    end

    context 'when range excludes end' do
      let(:range) { 1...3 }

      it 'keeps correct range' do
        is_expected.to eq(range)
      end
    end

    context 'when range is already a MarkerRange' do
      let(:range) { marker_range }

      it { is_expected.to be(marker_range) }
    end
  end
end
