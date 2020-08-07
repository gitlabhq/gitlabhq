# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Artifacts::ExpireInParser do
  describe '.validate_duration' do
    subject { described_class.validate_duration(value) }

    context 'with never' do
      let(:value) { 'never' }

      it { is_expected.to be_truthy }
    end

    context 'with never value camelized' do
      let(:value) { 'Never' }

      it { is_expected.to be_truthy }
    end

    context 'with a duration' do
      let(:value) { '1 Day' }

      it { is_expected.to be_truthy }
    end

    context 'without a duration' do
      let(:value) { 'something' }

      it { is_expected.to be_falsy }
    end
  end

  describe '#seconds_from_now' do
    subject { described_class.new(value).seconds_from_now }

    context 'with never' do
      let(:value) { 'never' }

      it { is_expected.to be_nil }
    end

    context 'with an empty string' do
      let(:value) { '' }

      it { is_expected.to be_nil }
    end

    context 'with a duration' do
      let(:value) { '1 day' }

      it { is_expected.to be_like_time(1.day.from_now) }
    end
  end
end
