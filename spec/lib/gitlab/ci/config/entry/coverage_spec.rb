# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Coverage do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context "when entry config value doesn't have the surrounding '/'" do
      let(:config) { 'Code coverage: \d+\.\d+' }

      describe '#errors' do
        subject { entry.errors }

        it { is_expected.to include(/coverage config must be a regular expression/) }
      end

      describe '#valid?' do
        subject { entry }

        it { is_expected.not_to be_valid }
      end
    end

    context "when entry config value has the surrounding '/'" do
      let(:config) { '/Code coverage: \d+\.\d+/' }

      describe '#value' do
        subject { entry.value }

        it { is_expected.to eq(config[1...-1]) }
      end

      describe '#errors' do
        subject { entry.errors }

        it { is_expected.to be_empty }
      end

      describe '#valid?' do
        subject { entry }

        it { is_expected.to be_valid }
      end
    end

    context 'when entry value is not valid' do
      let(:config) { '(malformed regexp' }

      describe '#errors' do
        subject { entry.errors }

        it { is_expected.to include(/coverage config must be a regular expression/) }
      end

      describe '#valid?' do
        subject { entry }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
