# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::ExtractChangesMetadataService, feature_category: :package_registry do
  describe '#execute' do
    let_it_be(:incoming) { create(:debian_incoming) }
    let_it_be(:temp_package) do
      create(:debian_package, without_package_files: true, with_changes_file: true, project: incoming.project)
    end

    let_it_be_with_reload(:source_file) { incoming.package_files.find_by(file_name: 'sample_1.2.3~alpha2.tar.xz') }
    let_it_be_with_reload(:dsc_file) { incoming.package_files.find_by(file_name: 'sample_1.2.3~alpha2.dsc') }
    let_it_be_with_reload(:changes_file) { temp_package.package_files.find_by(file_name: 'sample_1.2.3~alpha2_amd64.changes') }

    subject(:service) { described_class.new(changes_file).execute }

    context 'with valid package file' do
      it 'extract metadata', :aggregate_failures do
        expected_fields = { 'Architecture' => 'source amd64', 'Binary' => 'libsample0 sample-dev sample-udeb' }

        expect(subject[:file_type]).to eq(:changes)
        expect(subject[:architecture]).to be_nil
        expect(subject[:fields]).to include(expected_fields)
        expect(subject[:files].count).to eq(7)
      end
    end

    context 'with invalid changes file' do
      let_it_be(:changes_file) { incoming.package_files.find_by(file_name: 'sample-dev_1.2.3~binary_amd64.deb') }

      it 'raise ArgumentError', :aggregate_failures do
        expect { subject }.to raise_error(described_class::ExtractionError, "is not a changes file")
      end
    end

    context 'with invalid metadata' do
      let(:md5_dsc) { "#{dsc_file.file_md5} 671 libs optional sample_1.2.3~alpha2.dsc" }
      let(:md5_source) { "#{source_file.file_md5} 864 libs optional sample_1.2.3~alpha2.tar.xz" }
      let(:md5s) { "#{md5_dsc}\n#{md5_source}" }
      let(:sha1_dsc) { "#{dsc_file.file_sha1} 671 sample_1.2.3~alpha2.dsc" }
      let(:sha1_source) { "#{source_file.file_sha1} 864 sample_1.2.3~alpha2.tar.xz" }
      let(:sha1s) { "#{sha1_dsc}\n#{sha1_source}" }
      let(:sha256_dsc) { "#{dsc_file.file_sha256} 671 sample_1.2.3~alpha2.dsc" }
      let(:sha256_source) { "#{source_file.file_sha256} 864 sample_1.2.3~alpha2.tar.xz" }
      let(:sha256s) { "#{sha256_dsc}\n#{sha256_source}" }
      let(:fields) { { 'Files' => md5s, 'Checksums-Sha1' => sha1s, 'Checksums-Sha256' => sha256s } }
      let(:metadata) { { file_type: :changes, architecture: 'amd64', fields: fields } }

      before do
        allow_next_instance_of(::Packages::Debian::ExtractMetadataService) do |extract_metadata_service|
          allow(extract_metadata_service).to receive(:execute).and_return(metadata)
        end
      end

      context 'without Files field' do
        let(:md5s) { nil }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Files field is missing")
        end
      end

      context 'without Checksums-Sha1 field' do
        let(:sha1s) { nil }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Checksums-Sha1 field is missing")
        end
      end

      context 'without Checksums-Sha256 field' do
        let(:sha256s) { nil }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Checksums-Sha256 field is missing")
        end
      end

      context 'with file in Checksums-Sha1 but not in Files' do
        let(:md5_dsc) { '' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "sample_1.2.3~alpha2.dsc is listed in Checksums-Sha1 but not in Files")
        end
      end

      context 'with different size in Checksums-Sha1' do
        let(:sha1_dsc) { "#{dsc_file.file_sha1} 42 sample_1.2.3~alpha2.dsc" }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Size for sample_1.2.3~alpha2.dsc in Files and Checksums-Sha1 differ")
        end
      end

      context 'with file in Checksums-Sha256 but not in Files' do
        let(:md5_dsc) { '' }
        let(:sha1_dsc) { '' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "sample_1.2.3~alpha2.dsc is listed in Checksums-Sha256 but not in Files")
        end
      end

      context 'with different size in Checksums-Sha256' do
        let(:sha256_dsc) { "#{dsc_file.file_sha256} 42 sample_1.2.3~alpha2.dsc" }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Size for sample_1.2.3~alpha2.dsc in Files and Checksums-Sha256 differ")
        end
      end

      context 'with file in Files but not in Checksums-Sha1' do
        let(:sha1_dsc) { '' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Validation failed: Sha1sum can't be blank")
        end
      end

      context 'with file in Files but not in Checksums-Sha256' do
        let(:sha256_dsc) { '' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Validation failed: Sha256sum can't be blank")
        end
      end

      context 'with invalid MD5' do
        let(:md5_dsc) { '1234567890123456789012345678012 671 libs optional sample_1.2.3~alpha2.dsc' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Validation failed: Md5sum mismatch for sample_1.2.3~alpha2.dsc: #{dsc_file.file_md5} != 1234567890123456789012345678012")
        end
      end

      context 'with invalid SHA1' do
        let(:sha1_dsc) { '1234567890123456789012345678901234567890 671 sample_1.2.3~alpha2.dsc' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Validation failed: Sha1sum mismatch for sample_1.2.3~alpha2.dsc: #{dsc_file.file_sha1} != 1234567890123456789012345678901234567890")
        end
      end

      context 'with invalid SHA256' do
        let(:sha256_dsc) { '1234567890123456789012345678901234567890123456789012345678901234 671 sample_1.2.3~alpha2.dsc' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Validation failed: Sha256sum mismatch for sample_1.2.3~alpha2.dsc: #{dsc_file.file_sha256} != 1234567890123456789012345678901234567890123456789012345678901234")
        end
      end
    end

    context 'with missing package file' do
      let(:missing_file) { source_file }
      let(:missing_file_name) { source_file.file_name }

      before do
        missing_file.destroy!
      end

      it 'raise ArgumentError' do
        expect { subject }.to raise_error(described_class::ExtractionError, "#{missing_file_name} is listed in Files but was not uploaded")
      end
    end
  end
end
