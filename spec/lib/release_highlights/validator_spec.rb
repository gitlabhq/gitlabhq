# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleaseHighlights::Validator do
  let(:validator) { described_class.new(file: yaml_path) }
  let(:yaml_path) { 'spec/fixtures/whats_new/valid.yml' }
  let(:invalid_yaml_path) { 'spec/fixtures/whats_new/invalid.yml' }

  describe '#valid?' do
    subject { validator.valid? }

    context 'with a valid file' do
      it 'passes entries to entry validator and returns true' do
        expect(ReleaseHighlights::Validator::Entry).to receive(:new).exactly(:twice).and_call_original
        expect(subject).to be true
        expect(validator.errors).to be_empty
      end
    end

    context 'with invalid file' do
      let(:yaml_path) { invalid_yaml_path }

      it 'returns false and has errors' do
        expect(subject).to be false
        expect(validator.errors).not_to be_empty
      end
    end
  end

  describe '.validate_all!' do
    subject { described_class.validate_all! }

    before do
      allow(ReleaseHighlight).to receive(:file_paths).and_return(yaml_paths)
    end

    context 'with valid files' do
      let(:yaml_paths) { [yaml_path, yaml_path] }

      it { is_expected.to be true }
    end

    context 'with an invalid file' do
      let(:yaml_paths) { [invalid_yaml_path, yaml_path] }

      it { is_expected.to be false }
    end
  end

  describe '.error_message' do
    subject do
      described_class.validate_all!
      described_class.error_message
    end

    before do
      allow(ReleaseHighlight).to receive(:file_paths).and_return([yaml_path])
    end

    context 'with a valid file' do
      it { is_expected.to be_empty }
    end

    context 'with an invalid file' do
      let(:yaml_path) { invalid_yaml_path }

      it 'returns a nice error message' do
        expect(subject).to eq(<<-MESSAGE.strip_heredoc)
         ---------------------------------------------------------
         Validation failed for spec/fixtures/whats_new/invalid.yml
         ---------------------------------------------------------
         * Packages must be one of ["Free", "Premium", "Ultimate"] (line 6)

        MESSAGE
      end
    end
  end

  describe 'when validating all files' do
    # Permit DNS requests to validate all URLs in the YAML files
    it 'they should have no errors', :permit_dns do
      stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')

      expect(described_class.validate_all!).to be_truthy, described_class.error_message
    end
  end
end
