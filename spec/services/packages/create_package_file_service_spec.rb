# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::CreatePackageFileService do
  let(:package) { create(:maven_package) }

  describe '#execute' do
    context 'with valid params' do
      let(:params) do
        {
          file: Tempfile.new,
          file_name: 'foo.jar'
        }
      end

      it 'creates a new package file' do
        package_file = described_class.new(package, params).execute

        expect(package_file).to be_valid
        expect(package_file.file_name).to eq('foo.jar')
      end
    end

    context 'file is missing' do
      let(:params) do
        {
          file_name: 'foo.jar'
        }
      end

      it 'raises an error' do
        service = described_class.new(package, params)

        expect { service.execute }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
