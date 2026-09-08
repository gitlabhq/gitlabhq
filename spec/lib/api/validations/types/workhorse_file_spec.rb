# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Types::WorkhorseFile, feature_category: :source_code_management do
  describe '.parse' do
    context 'with a genuine UploadedFile' do
      let(:tempfile) { Tempfile.new('workhorse-file') }
      let(:uploaded_file) { UploadedFile.new(tempfile.path, filename: 'workhorse-file') }

      after do
        uploaded_file.close
        tempfile.close!
      end

      it 'returns the value' do
        expect(described_class.parse(uploaded_file)).to eq(uploaded_file)
      end
    end

    context 'with a blank value' do
      it 'returns nil', :aggregate_failures do
        expect(described_class.parse('')).to be_nil
        expect(described_class.parse(nil)).to be_nil
      end
    end

    context 'with a non-UploadedFile value' do
      it 'raises' do
        expect { described_class.parse('some string') }.to raise_error(/is not an UploadedFile type/)
      end
    end
  end
end
