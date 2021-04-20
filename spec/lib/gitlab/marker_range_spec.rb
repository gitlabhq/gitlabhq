# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::MarkerRange do
  subject(:marker_range) { described_class.new(first, last, mode: mode) }

  let(:first) { 1 }
  let(:last) { 10 }
  let(:mode) { nil }

  it { expect(marker_range.to_range).to eq(first..last) }

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
      is_expected.to eq(described_class.new(1, 3))
    end

    context 'when range excludes end' do
      let(:range) { 1...3 }

      it 'keeps correct range' do
        is_expected.to eq(described_class.new(1, 3, exclude_end: true))
      end
    end

    context 'when range is already a MarkerRange' do
      let(:range) { marker_range }

      it { is_expected.to be(marker_range) }
    end
  end

  describe '#==' do
    subject { default_marker_range == another_marker_range }

    let(:default_marker_range) { described_class.new(0, 1, mode: :addition) }
    let(:another_marker_range) { default_marker_range }

    it { is_expected.to be_truthy }

    context 'when marker ranges have different modes' do
      let(:another_marker_range) { described_class.new(0, 1, mode: :deletion) }

      it { is_expected.to be_falsey }
    end

    context 'when marker ranges have different ranges' do
      let(:another_marker_range) { described_class.new(0, 2, mode: :addition) }

      it { is_expected.to be_falsey }
    end

    context 'when marker ranges is a simple range' do
      let(:another_marker_range) { (0..1) }

      it { is_expected.to be_falsey }
    end
  end
end
