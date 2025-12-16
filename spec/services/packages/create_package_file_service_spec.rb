# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::CreatePackageFileService, feature_category: :package_registry do
  let_it_be(:package) { create(:generic_package) }
  let(:user) { package.creator }

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
        is_expected.to be_valid
          .and have_attributes(file_name: 'foo.jar', status: 'default', project_id: package.project_id)
      end

      it_behaves_like 'assigns build to package file'

      context 'when status is provided' do
        let(:status) { :processing }
        let(:params) { super().merge(status:) }

        it 'creates a new package file of status' do
          package_file = subject

          expect(package_file).to be_valid
          expect(package_file).to have_attributes(status: status.to_s)
        end
      end
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
