# frozen_string_literal: true

require 'spec_helper'
require 'rspec/parameterized'

RSpec.describe Gitlab::Utils::MimeType, feature_category: :shared do
  describe '.from_io' do
    subject { described_class.from_io(io) }

    context 'input is not an IO' do
      let(:io) { 'test' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'input is a file' do
      using RSpec::Parameterized::TableSyntax

      where(:fixture, :mime_type) do
        'banana_sample.gif'                 | 'image/gif'
        'rails_sample.jpg'                  | 'image/jpeg'
        'rails_sample.png'                  | 'image/png'
        'rails_sample.bmp'                  | 'image/bmp'
        'rails_sample.tif'                  | 'image/tiff'
        'sample.ico'                        | 'image/vnd.microsoft.icon'
        'sample_doc.md'                     | 'text/plain'
        'csv_empty.csv'                     | 'application/x-empty'
      end

      with_them do
        let(:io) { File.open(File.join(__dir__, '../../../fixtures', fixture)) }

        it { is_expected.to eq(mime_type) }
      end
    end
  end

  describe '.from_string' do
    subject { described_class.from_string(str) }

    context 'input is not a string' do
      let(:str) { nil }

      it { is_expected.to be_nil }
    end

    context 'input is a string' do
      let(:str) { 'plain text' }

      it { is_expected.to eq('text/plain') }
    end
  end

  describe '.from_filename' do
    using RSpec::Parameterized::TableSyntax

    shared_examples 'log determination' do
      it 'logs the determination' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          determined_content_type: mime_type
        )

        subject
      end
    end

    shared_examples 'not log determination' do
      it 'does not log the determination' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        subject
      end
    end

    context 'when default value is not given' do
      where(:filename, :mime_type, :log_enabled, :log_example) do
        1             | 'application/octet-stream' | false | 'not log determination'
        'test.tf'     | 'application/octet-stream' | false | 'not log determination'
        'test.css'    | 'text/css'                 | false | 'not log determination'
        'test.js'     | 'text/javascript'          | false | 'not log determination'
        1             | 'application/octet-stream' | true  | 'not log determination'
        'test.tf'     | 'application/octet-stream' | true  | 'log determination'
        'test.css'    | 'text/css'                 | true  | 'log determination'
        'test.js'     | 'text/javascript'          | true  | 'log determination'
      end

      with_them do
        subject { described_class.from_filename(filename, log_enabled: log_enabled) }

        it { is_expected.to eq(mime_type) }

        it_behaves_like params[:log_example]
      end
    end

    context 'when default value is given' do
      where(:filename, :default, :mime_type, :log_enabled, :log_example) do
        1          | nil          | nil          | false | 'not log determination'
        'test.tf'  | nil          | nil          | false | 'not log determination'
        'test.tf'  | 'text/plain' | 'text/plain' | false | 'not log determination'
        'test.css' | 'text/plain' | 'text/css'   | false | 'not log determination'
        1          | nil          | nil          | true  | 'not log determination'
        'test.tf'  | nil          | nil          | true  | 'log determination'
        'test.tf'  | 'text/plain' | 'text/plain' | true  | 'log determination'
        'test.css' | 'text/plain' | 'text/css'   | true  | 'log determination'
      end

      with_them do
        subject { described_class.from_filename(filename, default: default, log_enabled: log_enabled) }

        it { is_expected.to eq(mime_type) }

        it_behaves_like params[:log_example]
      end
    end
  end
end
