# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::CreatePackageFileService do
  let_it_be(:package) { create(:maven_package) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(package, params) }

  describe '#execute' do
    subject { service.execute }

    context 'with valid params' do
      let(:params) do
        {
          file: Tempfile.new,
          file_name: 'foo.jar'
        }
      end

      it 'creates a new package file' do
        package_file = subject

        expect(package_file).to be_valid
        expect(package_file.file_name).to eq('foo.jar')
      end

      it_behaves_like 'assigns build to package file'
    end

    context 'file is missing' do
      let(:params) do
        {
          file_name: 'foo.jar'
        }
      end

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
