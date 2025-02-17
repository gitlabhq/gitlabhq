# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::UserMapping::ReassignmentCsvValidator, feature_category: :importers do
  let(:raw_csv) do
    <<~CSV
      Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
      https://github.com,github,alice_1,Alice Alison,alice,alice-gl,alice@example.com
      https://github.com,github,bob_1,Bob Bobson,bob,,bob@example.com
    CSV
  end

  subject(:validator) { described_class.new(raw_csv) }

  describe '#valid?' do
    before do
      validator.valid?
    end

    it 'is truthy' do
      expect(validator.valid?).to be_truthy
    end

    it 'returns an empty set of errors' do
      expect(validator.errors).to be_empty
    end

    it 'is memoized' do
      validator = described_class.new(raw_csv)

      expect(validator).to receive(:validate!).once

      2.times { validator.valid? }
    end

    context 'when headers are missing' do
      let(:raw_csv) do
        <<~CSV
          Source host,Import type,Source user name,Source username,GitLab username,GitLab public email
          https://github.com,github,Alice Alison,alice,alice-gl,alice@example.com
        CSV
      end

      it 'is falsy' do
        expect(validator.valid?).to be_falsy
      end

      it 'returns an array of errors' do
        expect(validator.errors).to match_array(
          s_('UserMapping|The provided CSV was not correctly formatted.')
        )
      end
    end

    context 'when two rows have the same email address' do
      let(:raw_csv) do
        <<~CSV
          Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
          https://github.com,github,alice_1,Alice Alison,alice,alice-gl,alice@example.com
          https://github.com,github,bob_1,Bob Bobson,bob,,alice@example.com
        CSV
      end

      it 'is falsy' do
        expect(validator.valid?).to be_falsy
      end

      it 'returns an array of errors' do
        expect(validator.errors).to match_array(
          s_('UserMapping|The provided spreadsheet contains duplicate email addresses or usernames.')
        )
      end
    end

    context 'when two rows have the same username' do
      let(:raw_csv) do
        <<~CSV
          Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
          https://github.com,github,alice_1,Alice Alison,alice,alice-gl,alice@example.com
          https://github.com,github,bob_1,Bob Bobson,bob,alice-gl,bob@example.com
        CSV
      end

      it 'is falsy' do
        expect(validator.valid?).to be_falsy
      end

      it 'returns an array of errors' do
        expect(validator.errors).to match_array(
          s_('UserMapping|The provided spreadsheet contains duplicate email addresses or usernames.')
        )
      end
    end

    context 'when there is a missing header and a duplicated value' do
      let(:raw_csv) do
        <<~CSV
          Source host,GitLab public email
          https://github.com,alice@example.com
          https://github.com,alice@example.com
        CSV
      end

      it 'is falsy' do
        expect(validator.valid?).to be_falsy
      end

      it 'returns an array of errors' do
        expect(validator.errors).to match_array(
          [
            s_('UserMapping|The provided CSV was not correctly formatted.'),
            s_('UserMapping|The provided spreadsheet contains duplicate email addresses or usernames.')
          ]
        )
      end
    end

    context 'when usernames are duplicated for different source/host combos' do
      let(:raw_csv) do
        <<~CSV
          Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
          https://github.com,github,alice_1,Alice Alison,alice,alice-gl,alice@example.com
          https://gitlab.example,gitlab,alice_1,Alice Alison,alice,alice-gl,alice@example.com
        CSV
      end

      it 'is truthy' do
        expect(validator.valid?).to be_truthy
      end
    end
  end

  describe '#formatted_errors' do
    before do
      validator.valid?
    end

    context 'when there are no errors' do
      it { expect(validator.formatted_errors).to be_nil }
    end

    context 'when there is a missing header' do
      let(:raw_csv) do
        <<~CSV
          Source host,GitLab public email
          https://github.com,alice@example.com
        CSV
      end

      it 'returns a formatted error string' do
        expect(validator.formatted_errors).to eq(
          'The following errors are preventing the sheet from being processed: ' \
            'The provided CSV was not correctly formatted.'
        )
      end
    end

    context 'when there is a duplicated value' do
      let(:raw_csv) do
        <<~CSV
          Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
          https://github.com,github,alice_1,Alice Alison,alice,alice-gl,alice@example.com
          https://github.com,github,bob_1,Bob Bobson,bob,,alice@example.com
        CSV
      end

      it 'returns a formatted error string' do
        expect(validator.formatted_errors).to eq(
          'The following errors are preventing the sheet from being processed: ' \
            'The provided spreadsheet contains duplicate email addresses or usernames.'
        )
      end
    end

    context 'when there is a missing header and a duplicated value' do
      let(:raw_csv) do
        <<~CSV
          Source host,GitLab public email
          https://github.com,alice@example.com
          https://github.com,alice@example.com
        CSV
      end

      it 'returns a formatted error string' do
        expect(validator.formatted_errors).to eq(
          'The following errors are preventing the sheet from being processed: ' \
            'The provided CSV was not correctly formatted. ' \
            'The provided spreadsheet contains duplicate email addresses or usernames.'
        )
      end
    end
  end
end
