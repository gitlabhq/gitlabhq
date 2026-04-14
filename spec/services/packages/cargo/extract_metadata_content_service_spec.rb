# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cargo::ExtractMetadataContentService, feature_category: :package_registry do
  describe '#execute' do
    subject(:result) { service.execute }

    # Helper to build Cargo publish format: [4-byte JSON length][JSON][4-byte crate length][crate data]
    def build_cargo_publish_request(index_content:, crate_data:)
      json_bytes = Gitlab::Json.dump(index_content)
      json_length = [json_bytes.bytesize].pack('L<') # little-endian uint32
      crate_length = [crate_data.bytesize].pack('L<') # little-endian uint32

      StringIO.new(json_length + json_bytes + crate_length + crate_data)
    end

    context 'with valid cargo publish request' do
      let(:index_content) do
        {
          name: 'test-crate',
          vers: '1.0.0',
          deps: [
            { name: 'dep_1', req: '^0.6' }
          ],
          cksum: '1234567890abcdef',
          v: 2
        }
      end

      let(:crate_data) { 'binary crate data content' }

      let(:cargo_file_content) { build_cargo_publish_request(index_content: index_content, crate_data: crate_data) }
      let(:service) { described_class.new(cargo_file_content) }

      it 'returns success response' do
        expect(result).to be_success
      end

      it 'extracts index_content and crate_data', :aggregate_failures do
        payload = result.payload

        expect(payload).to have_key(:index_content)
        expect(payload).to have_key(:crate_data)
      end

      it 'parses index_content correctly' do
        payload = result.payload
        extracted_index = payload[:index_content]

        expect(extracted_index[:name]).to eq('test-crate')
        expect(extracted_index[:vers]).to eq('1.0.0')
        expect(extracted_index[:deps]).to be_an(Array)
        expect(extracted_index[:deps].first[:name]).to eq('dep_1')
        expect(extracted_index[:deps].first[:req]).to eq('^0.6')
        expect(extracted_index[:cksum]).to eq('1234567890abcdef')
        expect(extracted_index[:v]).to eq(2)
      end

      it 'extracts crate_data correctly' do
        payload = result.payload

        expect(payload[:crate_data]).to eq(crate_data)
      end

      it 'symbolizes keys in index_content' do
        payload = result.payload
        extracted_index = payload[:index_content]

        expect(extracted_index.keys).to all(be_a(Symbol))
      end
    end

    context 'with index_content containing dependencies' do
      let(:index_content) do
        {
          name: 'test-package',
          vers: '2.3.4',
          deps: [
            { name: 'serde', req: '^1.0' },
            { name: 'tokio', req: '^1.0', features: %w[rt macros] }
          ],
          cksum: 'abcdef123456',
          v: 2
        }
      end

      let(:crate_data) { 'crate binary' }

      let(:cargo_file_content) { build_cargo_publish_request(index_content: index_content, crate_data: crate_data) }
      let(:service) { described_class.new(cargo_file_content) }

      it 'extracts all dependencies' do
        payload = result.payload
        deps = payload[:index_content][:deps]

        expect(deps.length).to eq(2)
        expect(deps).to include(
          hash_including(name: 'serde', req: '^1.0')
        )
        expect(deps).to include(
          hash_including(name: 'tokio', req: '^1.0', features: %w[rt macros])
        )
      end
    end

    context 'with empty crate_data' do
      let(:index_content) { { name: 'test', vers: '1.0.0', cksum: 'abc', v: 2 } }
      let(:crate_data) { '' }
      let(:cargo_file_content) { build_cargo_publish_request(index_content: index_content, crate_data: crate_data) }
      let(:service) { described_class.new(cargo_file_content) }

      it 'returns error response' do
        expect(result).to be_error
      end

      it 'returns crate length error message' do
        expect(result.message).to match(/crate length must be positive/)
      end
    end

    context 'with empty index_content' do
      let(:empty_json) { '' }
      let(:crate_data) { 'crate data' }
      let(:json_length) { [0].pack('L<') }
      let(:crate_length) { [crate_data.bytesize].pack('L<') }
      let(:cargo_file_content) { StringIO.new(json_length + empty_json + crate_length + crate_data) }
      let(:service) { described_class.new(cargo_file_content) }

      it 'returns error response' do
        expect(result).to be_error
      end

      it 'returns JSON length error message' do
        expect(result.message).to match(/JSON length must be positive/)
      end
    end

    context 'with invalid JSON in index_content' do
      let(:invalid_json) { '{ "name": "test", invalid json }' }
      let(:crate_data) { 'crate data' }
      let(:json_length) { [invalid_json.bytesize].pack('L<') }
      let(:crate_length) { [crate_data.bytesize].pack('L<') }
      let(:cargo_file_content) { StringIO.new(json_length + invalid_json + crate_length + crate_data) }
      let(:service) { described_class.new(cargo_file_content) }

      it 'returns error response' do
        expect(result).to be_error
      end

      it 'returns JSON parser error message' do
        expect(result.message).to match(/Invalid JSON metadata/)
      end
    end

    context 'with truncated JSON length' do
      let(:index_content) { { name: 'test', vers: '1.0.0', cksum: 'abc', v: 2 } }
      let(:json_bytes) { Gitlab::Json.dump(index_content) }
      let(:json_length) { [json_bytes.bytesize + 10].pack('L<') } # Claim more bytes than available
      let(:cargo_file_content) { StringIO.new(json_length + json_bytes) } # Missing crate length + data
      let(:service) { described_class.new(cargo_file_content) }

      it 'returns error response' do
        expect(result).to be_error
      end

      it 'returns EOF error message' do
        expect(result.message).to match(/Failed to extract metadata/)
      end
    end

    context 'with truncated crate length' do
      let(:index_content) { { name: 'test', vers: '1.0.0', cksum: 'abc', v: 2 } }
      let(:crate_data) { 'partial' }
      let(:json_bytes) { Gitlab::Json.dump(index_content) }
      let(:json_length) { [json_bytes.bytesize].pack('L<') }
      let(:crate_length) { [crate_data.bytesize + 10].pack('L<') } # Claim more bytes than available
      # Truncated crate data
      let(:cargo_file_content) { StringIO.new(json_length + json_bytes + crate_length + crate_data[0..2]) }
      let(:service) { described_class.new(cargo_file_content) }

      it 'returns error response' do
        expect(result).to be_error
      end

      it 'returns EOF error message' do
        expect(result.message).to match(/Failed to extract metadata/)
      end
    end

    context 'with crate size exceeds maximum allowed' do
      let(:crate_data) { 'a' * 11.megabytes }
      let(:index_content) { { name: 'test', vers: '1.0.0', cksum: 'abc', v: 2 } }
      let(:cargo_file_content) { build_cargo_publish_request(index_content: index_content, crate_data: crate_data) }
      let(:service) { described_class.new(cargo_file_content) }

      it 'returns error response' do
        expect(result).to be_error
      end

      it 'returns crate size exceeds maximum allowed error message' do
        expect(result.message).to match(/Crate size exceeds maximum allowed/)
      end
    end

    context 'with missing JSON length bytes' do
      let(:cargo_file_content) { StringIO.new('ab') } # Only 2 bytes, need 4 for length
      let(:service) { described_class.new(cargo_file_content) }

      it 'returns error response' do
        expect(result).to be_error
      end

      it 'returns EOF error message' do
        expect(result.message).to match(/Failed to extract metadata/)
      end
    end

    context 'with empty file' do
      let(:cargo_file_content) { StringIO.new('') }
      let(:service) { described_class.new(cargo_file_content) }

      it 'returns error response' do
        expect(result).to be_error
      end

      it 'returns EOF error message' do
        expect(result.message).to match(/Failed to extract metadata/)
      end
    end

    context 'with nil file content' do
      let(:service) { described_class.new(nil) }

      it 'handles nil gracefully' do
        # nil.rewind should not raise, but reading will fail
        expect { result }.not_to raise_error
      end

      it 'returns error response' do
        expect(result).to be_error
      end
    end

    context 'with file that can be rewound' do
      let(:index_content) { { name: 'test', vers: '1.0.0', cksum: 'abc', v: 2 } }
      let(:crate_data) { 'data' }
      let(:cargo_file_content) { build_cargo_publish_request(index_content: index_content, crate_data: crate_data) }
      let(:service) { described_class.new(cargo_file_content) }

      before do
        # Simulate reading some bytes first
        cargo_file_content.read(5)
      end

      it 'rewinds the file before reading' do
        # Should still work even though we read some bytes first
        expect(result).to be_success
        expect(result.payload[:index_content][:name]).to eq('test')
      end
    end
  end
end
