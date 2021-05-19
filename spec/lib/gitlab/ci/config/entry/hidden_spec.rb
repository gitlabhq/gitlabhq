# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Hidden do
  describe '.matching?' do
    subject { described_class.matching?(name, {}) }

    context 'when name starts with dot' do
      let(:name) { '.hidden_job' }

      it { is_expected.to be_truthy }
    end

    context 'when name does not start with dot' do
      let(:name) { 'rspec' }

      it { is_expected.to be_falsey }
    end
  end

  describe '.new' do
    let(:config) { {} }
    let(:entry) { described_class.new(config) }

    describe 'validations' do
      context 'when entry config value is correct' do
        let(:config) { [:some, :array] }

        describe '#value' do
          it 'returns key value' do
            expect(entry.value).to eq [:some, :array]
          end
        end

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end

      context 'when entry value is not correct' do
        context 'when config is empty' do
          describe '#valid' do
            it 'is invalid' do
              expect(entry).not_to be_valid
            end
          end
        end
      end
    end

    describe '#leaf?' do
      it 'is a leaf' do
        expect(entry).to be_leaf
      end
    end

    describe '#relevant?' do
      it 'is not a relevant entry' do
        expect(entry).not_to be_relevant
      end
    end
  end
end
