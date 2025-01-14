# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::Symbols::CreateSymbolFilesService, feature_category: :package_registry do
  let_it_be(:package) { create(:nuget_package) }
  let_it_be(:package_file) do
    create(:package_file, :snupkg, package: package,
      file_fixture: expand_fixture_path('packages/nuget/package_with_symbols.snupkg'))
  end

  let(:package_zip_file) { Zip::File.new(package_file.file) }
  let(:service) { described_class.new(package, package_zip_file) }

  describe '#execute' do
    subject { service.execute }

    shared_examples 'logging an error' do |error_class|
      it 'logs the error' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(error_class),
          class: described_class.name,
          package_id: package.id
        )

        subject
      end
    end

    context 'when symbol files are found' do
      it 'creates a symbol record and extracts the signature', :aggregate_failures do
        expect_next_instance_of(Packages::Nuget::Symbols::ExtractSignatureAndChecksumService,
          instance_of(File)) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        expect { subject }.to change { package.nuget_symbols.count }.by(1)
        expect(package.nuget_symbols.last.project_id).to eq(package.project_id)
      end
    end

    context 'when symbol files hit the limit' do
      before do
        stub_const("#{described_class}::SYMBOL_ENTRIES_LIMIT", 0)
      end

      it 'does not create a symbol record' do
        expect { subject }.not_to change { package.nuget_symbols.count }
      end

      it_behaves_like 'logging an error', described_class::ExtractionError
    end

    context 'without a signature' do
      before do
        allow_next_instance_of(Packages::Nuget::Symbols::ExtractSignatureAndChecksumService) do |instance|
          allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: { signature: nil }))
        end
      end

      it 'does not call create! on the symbol record' do
        expect(::Packages::Nuget::Symbol).not_to receive(:create!)

        subject
      end
    end

    context 'without a checksum' do
      before do
        allow_next_instance_of(Packages::Nuget::Symbols::ExtractSignatureAndChecksumService) do |instance|
          allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: { checksum: nil }))
        end
      end

      it 'does not call create! on the symbol record' do
        expect(::Packages::Nuget::Symbol).not_to receive(:create!)

        subject
      end
    end

    context 'with existing duplicate symbol records' do
      let_it_be(:symbol) { create(:nuget_symbol, package: package) }

      before do
        allow_next_instance_of(Packages::Nuget::Symbols::ExtractSignatureAndChecksumService) do |instance|
          allow(instance).to receive(:execute).and_return(
            ServiceResponse.success(payload: { signature: symbol.signature, checksum: symbol.file_sha256 })
          )
        end
      end

      it 'does not create a symbol record' do
        expect { subject }.not_to change { package.nuget_symbols.count }
      end
    end

    context 'when a symbol file has the wrong entry size' do
      before do
        allow_next_instance_of(Zip::Entry) do |instance|
          allow(instance).to receive(:extract).and_raise(Zip::EntrySizeError)
        end
      end

      it_behaves_like 'logging an error', described_class::ExtractionError
    end

    context 'when a symbol file has the wrong entry name' do
      before do
        allow_next_instance_of(Zip::Entry) do |instance|
          allow(instance).to receive(:extract).and_raise(Zip::EntryNameError)
        end
      end

      it_behaves_like 'logging an error', described_class::ExtractionError
    end
  end
end
