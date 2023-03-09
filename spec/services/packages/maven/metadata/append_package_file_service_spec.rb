# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Maven::Metadata::AppendPackageFileService, feature_category: :package_registry do
  let_it_be(:package) { create(:maven_package, version: nil) }

  let(:service) { described_class.new(package: package, metadata_content: content) }
  let(:content) { 'test' }

  describe '#execute' do
    subject { service.execute }

    context 'with some content' do
      it 'creates all the related package files', :aggregate_failures do
        expect { subject }.to change { package.package_files.count }.by(5)
        expect(subject).to be_success

        expect_file(metadata_file_name, with_content: content, with_content_type: 'application/xml')
        expect_file("#{metadata_file_name}.md5")
        expect_file("#{metadata_file_name}.sha1")
        expect_file("#{metadata_file_name}.sha256")
        expect_file("#{metadata_file_name}.sha512")
      end

      context 'with FIPS mode', :fips_mode do
        it 'does not generate file_md5' do
          expect { subject }.to change { package.package_files.count }.by(4)
          expect(subject).to be_success

          expect_file(metadata_file_name, with_content: content, with_content_type: 'application/xml', fips: true)
          expect_file("#{metadata_file_name}.sha1", fips: true)
          expect_file("#{metadata_file_name}.sha256", fips: true)
          expect_file("#{metadata_file_name}.sha512", fips: true)
        end
      end
    end

    context 'with nil content' do
      let(:content) { nil }

      it_behaves_like 'returning an error service response', message: 'metadata content is not set'
    end

    context 'with nil package' do
      let(:package) { nil }

      it_behaves_like 'returning an error service response', message: 'package is not set'
    end

    def expect_file(file_name, fips: false, with_content: nil, with_content_type: '')
      package_file = package.package_files.recent.with_file_name(file_name).first

      expect(package_file.file).to be_present
      expect(package_file.file_name).to eq(file_name)
      expect(package_file.size).to be > 0
      expect(package_file.file_sha1).to be_present
      expect(package_file.file_sha256).to be_present
      expect(package_file.file.content_type).to eq(with_content_type)

      if fips
        expect(package_file.file_md5).not_to be_present
      else
        expect(package_file.file_md5).to be_present
      end

      if with_content
        expect(package_file.file.read).to eq(with_content)
      end
    end

    def metadata_file_name
      ::Packages::Maven::Metadata.filename
    end
  end
end
