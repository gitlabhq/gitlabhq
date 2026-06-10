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
    context 'when the CSV is safe to parse' do
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

    context 'when the CSV is not safe to parse' do
      context 'when the SafeValidator raises a SizeLimitError' do
        let(:raw_csv) { "headers\n" }

        before do
          stub_const("#{described_class}::MAX_CSV_SIZE", 4)
          validator.valid?
        end

        it 'translates it to the UserMapping size error' do
          expect(validator.errors).to contain_exactly(
            'The provided CSV file exceeds the maximum size of 4 B.'
          )
        end
      end

      context 'when the SafeValidator raises a DelimiterLimitError' do
        let(:raw_csv) { "a,b,c\n1,2,3\n" }

        before do
          stub_const("#{described_class}::MAX_CSV_DELIMITERS", 3)
          validator.valid?
        end

        it 'translates it to the UserMapping rows-or-columns error' do
          expect(validator.errors).to contain_exactly(
            'The provided CSV file has too many rows or columns to be processed.'
          )
        end
      end

      context 'when the SafeValidator raises a HeaderColumnLimitError' do
        let(:raw_csv) { "a,b,c,d\n" }

        before do
          stub_const("#{described_class}::MAX_CSV_HEADER_COLUMNS", 3)
          validator.valid?
        end

        it 'translates it to the UserMapping column-count error and skips invalid header detection' do
          expect(validator.errors).to contain_exactly(
            'The provided CSV file exceeds the maximum number of columns (3).'
          )
        end
      end

      context 'when the SafeValidator raises a RowLimitError' do
        let(:raw_csv) do
          <<~CSV
            Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
            https://github.com,github,alice_1,Alice Alison,alice,alice-gl,alice@example.com
            https://github.com,github,alice_1,Alice Alison,alice,alice-gl,alice@example.com
          CSV
        end

        before do
          stub_const("#{described_class}::MAX_CSV_ROWS", 1)
          validator.valid?
        end

        it 'translates it to the UserMapping row-count error and skips duplicate detection' do
          # The CSV also has duplicates; only the row-count error appears, which
          # proves duplicate detection was skipped.
          expect(validator.errors).to contain_exactly(
            'The provided CSV file exceeds the maximum number of rows (1).'
          )
        end
      end

      context 'when the SafeValidator raises an unknown LimitExceededError subclass' do
        let(:raw_csv) { "a,b,c\n" }

        before do
          allow_next_instance_of(::Gitlab::SafeCsvValidator) do |instance|
            allow(instance).to receive(:validate!).and_raise(::Gitlab::SafeCsvValidator::LimitExceededError)
          end
          validator.valid?
        end

        it 'falls back to a generic UserMapping error message' do
          expect(validator.errors).to contain_exactly(
            'The provided CSV file could not be processed.'
          )
        end
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
