require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Key do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    shared_examples 'key with slash' do
      it 'is invalid' do
        expect(entry).not_to be_valid
      end

      it 'reports errors with config value' do
        expect(entry.errors).to include 'key config cannot contain the "/" character'
      end
    end

    shared_examples 'key with only dots' do
      it 'is invalid' do
        expect(entry).not_to be_valid
      end

      it 'reports errors with config value' do
        expect(entry.errors).to include 'key config cannot be "." or ".."'
      end
    end

    context 'when entry config value is correct' do
      let(:config) { 'test' }

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq 'test'
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      let(:config) { ['incorrect'] }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'key config should be a string or symbol'
        end
      end
    end

    context 'when entry value contains slash' do
      let(:config) { 'key/with/some/slashes' }

      it_behaves_like 'key with slash'
    end

    context 'when entry value contains URI encoded slash (%2F)' do
      let(:config) { 'key%2Fwith%2Fsome%2Fslashes' }

      it_behaves_like 'key with slash'
    end

    context 'when entry value is a dot' do
      let(:config) { '.' }

      it_behaves_like 'key with only dots'
    end

    context 'when entry value is two dots' do
      let(:config) { '..' }

      it_behaves_like 'key with only dots'
    end

    context 'when entry value is a URI encoded dot (%2E)' do
      let(:config) { '%2e' }

      it_behaves_like 'key with only dots'
    end

    context 'when entry value is two URI encoded dots (%2E)' do
      let(:config) { '%2E%2e' }

      it_behaves_like 'key with only dots'
    end

    context 'when entry value is one dot and one URI encoded dot' do
      let(:config) { '.%2e' }

      it_behaves_like 'key with only dots'
    end
  end

  describe '.default' do
    it 'returns default key' do
      expect(described_class.default).to eq 'default'
    end
  end
end
