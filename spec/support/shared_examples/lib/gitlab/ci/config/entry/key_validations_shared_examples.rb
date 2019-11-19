# frozen_string_literal: true

RSpec.shared_examples 'key entry validations' do |config_name|
  shared_examples 'key with slash' do
    it 'is invalid' do
      expect(entry).not_to be_valid
    end

    it 'reports errors with config value' do
      expect(entry.errors).to include "#{config_name} config cannot contain the \"/\" character"
    end
  end

  shared_examples 'key with only dots' do
    it 'is invalid' do
      expect(entry).not_to be_valid
    end

    it 'reports errors with config value' do
      expect(entry.errors).to include "#{config_name} config cannot be \".\" or \"..\""
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

  context 'when key is a string' do
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
end
