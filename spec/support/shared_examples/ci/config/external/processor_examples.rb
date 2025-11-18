# frozen_string_literal: true

# Shared examples for External::Processor and Header::Processor
#
# These examples test common behavior across both processor types.
# The including spec must define:
#   - processor: instance of the processor being tested
#   - values: the input hash to process
#   - project_files: hash of files to create in the project
#   - remote_file: URL for remote file tests
#
RSpec.shared_examples 'handles invalid local files' do
  context 'when an invalid local file is defined' do
    let(:values) do
      {
        include: invalid_local_file_include,
        **base_values
      }
    end

    it 'raises an error' do
      expect { processor.perform }.to raise_error(
        described_class::IncludeError,
        /Local file .* does not exist/
      )
    end
  end
end

RSpec.shared_examples 'handles invalid remote files' do
  context 'when an invalid remote file is defined' do
    let(:remote_file) { invalid_remote_file }
    let(:values) do
      {
        include: { remote: remote_file },
        **base_values
      }
    end

    before do
      stub_full_request(remote_file).and_raise(SocketError.new('Some HTTP error'))
    end

    it 'raises an error' do
      expect { processor.perform }.to raise_error(
        described_class::IncludeError,
        /Remote file .* could not be fetched because of a socket error/
      )
    end
  end
end

RSpec.shared_examples 'processes valid external files' do
  context 'with a valid local external file' do
    let(:values) do
      {
        include: valid_local_file_include,
        **base_values
      }
    end

    it 'merges the external file content' do
      result = processor.perform
      expect(result).to be_a(Hash)
      expect(result).not_to be_empty
    end

    it "removes the 'include' keyword" do
      expect(processor.perform[:include]).to be_nil
    end
  end

  context 'with a valid remote external file' do
    let(:remote_file) { valid_remote_file }
    let(:values) do
      {
        include: { remote: remote_file },
        **base_values
      }
    end

    before do
      stub_full_request(remote_file).to_return(body: valid_remote_file_content)
    end

    it 'merges the external file content' do
      result = processor.perform
      expect(result).to be_a(Hash)
      expect(result).not_to be_empty
    end

    it "removes the 'include' keyword" do
      expect(processor.perform[:include]).to be_nil
    end
  end
end

RSpec.shared_examples 'processes multiple external files' do
  context 'with multiple external files' do
    let(:remote_file) { valid_remote_file }
    let(:values) do
      {
        include: multiple_includes,
        **base_values
      }
    end

    before do
      if respond_to?(:valid_remote_file_content)
        stub_full_request(remote_file).to_return(body: valid_remote_file_content)
      end
    end

    it 'merges all external files' do
      result = processor.perform
      expect(result).to be_a(Hash)
      expect(result).not_to be_empty
    end

    it "removes the 'include' keyword" do
      expect(processor.perform[:include]).to be_nil
    end
  end
end

RSpec.shared_examples 'returns values when no includes defined' do
  context 'when no external files defined' do
    let(:values) { base_values }

    it 'returns the same values' do
      expect(processor.perform).to eq(values)
    end
  end
end
