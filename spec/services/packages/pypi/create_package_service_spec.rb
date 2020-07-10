# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Pypi::CreatePackageService do
  include PackagesManagerApiSpecHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:params) do
    {
      name: 'foo',
      version: '1.0',
      content: temp_file('foo.tgz'),
      requires_python: '>=2.7',
      sha256_digest: '123',
      md5_digest: '567'
    }
  end

  describe '#execute' do
    subject { described_class.new(project, user, params).execute }

    let(:created_package) { Packages::Package.pypi.last }

    context 'without an existing package' do
      it 'creates the package' do
        expect { subject }.to change { Packages::Package.pypi.count }.by(1)

        expect(created_package.name).to eq 'foo'
        expect(created_package.version).to eq '1.0'

        expect(created_package.pypi_metadatum.required_python).to eq '>=2.7'
        expect(created_package.package_files.size).to eq 1
        expect(created_package.package_files.first.file_name).to eq 'foo.tgz'
        expect(created_package.package_files.first.file_sha256).to eq '123'
        expect(created_package.package_files.first.file_md5).to eq '567'
      end
    end

    context 'with an existing package' do
      before do
        described_class.new(project, user, params).execute
      end

      context 'with an existing file' do
        before do
          params[:content] = temp_file('foo.tgz')
          params[:sha256_digest] = 'abc'
          params[:md5_digest] = 'def'
        end

        it 'replaces the file' do
          expect { subject }
            .to change { Packages::Package.pypi.count }.by(0)
            .and change { Packages::PackageFile.count }.by(1)

          expect(created_package.package_files.size).to eq 2
          expect(created_package.package_files.first.file_name).to eq 'foo.tgz'
          expect(created_package.package_files.first.file_sha256).to eq '123'
          expect(created_package.package_files.first.file_md5).to eq '567'
          expect(created_package.package_files.last.file_name).to eq 'foo.tgz'
          expect(created_package.package_files.last.file_sha256).to eq 'abc'
          expect(created_package.package_files.last.file_md5).to eq 'def'
        end
      end

      context 'without an existing file' do
        before do
          params[:content] = temp_file('another.tgz')
        end

        it 'adds the file' do
          expect { subject }
            .to change { Packages::Package.pypi.count }.by(0)
            .and change { Packages::PackageFile.count }.by(1)

          expect(created_package.package_files.size).to eq 2
          expect(created_package.package_files.map(&:file_name).sort).to eq ['another.tgz', 'foo.tgz']
        end
      end
    end
  end
end
