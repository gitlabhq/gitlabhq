# frozen_string_literal: true

require 'spec_helper'

describe Issues::ImportCsvService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject do
    uploader = FileUploader.new(project)
    uploader.store!(file)

    described_class.new(user, project, uploader).execute
  end

  describe '#execute' do
    context 'invalid file' do
      let(:file) { fixture_file_upload('spec/fixtures/banana_sample.gif') }

      it 'returns invalid file error' do
        expect_next_instance_of(Notify) do |instance|
          expect(instance).to receive(:import_issues_csv_email)
        end

        expect(subject[:success]).to eq(0)
        expect(subject[:parse_error]).to eq(true)
      end
    end

    context 'comma delimited file' do
      let(:file) { fixture_file_upload('spec/fixtures/csv_comma.csv') }

      it 'imports CSV without errors' do
        expect_next_instance_of(Notify) do |instance|
          expect(instance).to receive(:import_issues_csv_email)
        end

        expect(subject[:success]).to eq(3)
        expect(subject[:error_lines]).to eq([])
        expect(subject[:parse_error]).to eq(false)
      end
    end

    context 'tab delimited file with error row' do
      let(:file) { fixture_file_upload('spec/fixtures/csv_tab.csv') }

      it 'imports CSV with some error rows' do
        expect_next_instance_of(Notify) do |instance|
          expect(instance).to receive(:import_issues_csv_email)
        end

        expect(subject[:success]).to eq(2)
        expect(subject[:error_lines]).to eq([3])
        expect(subject[:parse_error]).to eq(false)
      end
    end

    context 'semicolon delimited file with CRLF' do
      let(:file) { fixture_file_upload('spec/fixtures/csv_semicolon.csv') }

      it 'imports CSV with a blank row' do
        expect_next_instance_of(Notify) do |instance|
          expect(instance).to receive(:import_issues_csv_email)
        end

        expect(subject[:success]).to eq(3)
        expect(subject[:error_lines]).to eq([4])
        expect(subject[:parse_error]).to eq(false)
      end
    end
  end
end
