# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::UpdatePackageFileService, feature_category: :package_registry do
  let_it_be(:another_package) { create(:generic_package) }
  let_it_be(:old_file_name) { 'old_file_name.txt' }
  let_it_be(:new_file_name) { 'new_file_name.txt' }

  let(:package) { package_file.package }
  let(:params) { { package_id: another_package.id, file_name: new_file_name } }
  let(:service) { described_class.new(package_file, params) }

  describe '#execute' do
    subject { service.execute }

    shared_examples 'updating package file with valid parameters' do
      context 'with both parameters set' do
        it 'updates the package file accordingly' do
          expect { subject }
            .to change { package.package_files.count }.from(1).to(0)
            .and change { another_package.package_files.count }.from(0).to(1)
            .and change { package_file.package_id }.from(package.id).to(another_package.id)
            .and change { package_file.file_name }.from(old_file_name).to(new_file_name)
        end
      end

      context 'with only file_name set' do
        let(:params) { { file_name: new_file_name } }

        it 'updates the package file accordingly' do
          expect { subject }
            .to not_change { package.package_files.count }
            .and not_change { another_package.package_files.count }
            .and not_change { package_file.package_id }
            .and change { package_file.file_name }.from(old_file_name).to(new_file_name)
        end
      end

      context 'with only package_id set' do
        let(:params) { { package_id: another_package.id } }

        it 'updates the package file accordingly' do
          expect { subject }
            .to change { package.package_files.count }.from(1).to(0)
            .and change { another_package.package_files.count }.from(0).to(1)
            .and change { package_file.package_id }.from(package.id).to(another_package.id)
            .and not_change { package_file.file_name }
        end
      end
    end

    shared_examples 'not updating package with invalid parameters' do
      context 'with blank parameters' do
        let(:params) { {} }

        it 'raise an argument error' do
          expect { subject }.to raise_error(ArgumentError, 'package_id and file_name are blank')
        end
      end

      context 'with non persisted package file' do
        let(:package_file) { build(:package_file) }

        it 'raise an argument error' do
          expect { subject }.to raise_error(ArgumentError, 'package_file not persisted')
        end
      end
    end

    context 'with object storage disabled' do
      let(:package_file) { create(:package_file, file_name: old_file_name) }

      before do
        stub_package_file_object_storage(enabled: false)
      end

      it_behaves_like 'updating package file with valid parameters' do
        before do
          expect(package_file).to receive(:remove_previously_stored_file).and_call_original
          expect(package_file).not_to receive(:move_in_object_storage)
        end
      end

      it_behaves_like 'not updating package with invalid parameters'
    end

    context 'with object storage enabled' do
      let(:package_file) do
        create(
          :package_file,
          file_name: old_file_name,
          file: CarrierWaveStringFile.new_file(
            file_content: 'content',
            filename: old_file_name,
            content_type: 'text/plain'
          ),
          file_store: ::Packages::PackageFileUploader::Store::REMOTE
        )
      end

      before do
        stub_package_file_object_storage(enabled: true)
      end

      it_behaves_like 'updating package file with valid parameters' do
        before do
          expect(package_file).not_to receive(:remove_previously_stored_file)
          expect(package_file).to receive(:move_in_object_storage).and_call_original
        end
      end

      it_behaves_like 'not updating package with invalid parameters' do
        before do
          expect(package_file.file.file).not_to receive(:copy_to)
        end
      end
    end
  end
end
