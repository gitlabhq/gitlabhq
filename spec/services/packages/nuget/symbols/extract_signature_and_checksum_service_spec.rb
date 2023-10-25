# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::Symbols::ExtractSignatureAndChecksumService, feature_category: :package_registry do
  let_it_be(:symbol_file_path) { expand_fixture_path('packages/nuget/symbol/package.pdb') }
  let(:symbol_file) { File.new(symbol_file_path) }

  let(:service) { described_class.new(symbol_file) }

  after do
    symbol_file.close
  end

  describe '#execute' do
    subject { service.execute }

    context 'with a valid symbol file' do
      it 'returns the signature and checksum' do
        payload = subject.payload

        expect(payload[:signature]).to eq('b91a152048fc4b3883bf3cf73fbc03f1FFFFFFFF')
        expect(payload[:checksum]).to eq('20151ab9fc48384b83bf3cf73fbc03f1d49166cc356139845f290d1d315256c0')
      end

      it 'reads the file in chunks' do
        expect(symbol_file).to receive(:read).with(described_class::GUID_CHUNK_SIZE).and_call_original
        expect(symbol_file).to receive(:read).with(described_class::SHA_CHUNK_SIZE, instance_of(String))
          .at_least(:once).and_call_original

        subject
      end
    end

    context 'with an invalid symbol file' do
      before do
        allow(symbol_file).to receive(:read).and_return('invalid')
      end

      it 'returns an error' do
        expect(subject).to be_error
        expect(subject.message).to eq('Could not find the signature in the symbol file')
      end
    end
  end
end
