require 'spec_helper'

describe ContainerRegistry::Blob do
  let(:digest) { 'sha256:0123456789012345' }
  let(:config) do
    {
      'digest' => digest,
      'mediaType' => 'binary',
      'size' => 1000
    }
  end
  let(:token) { 'authorization-token' }
  
  let(:registry) { ContainerRegistry::Registry.new('http://example.com', token: token) }
  let(:repository) { registry.repository('group/test') }
  let(:blob) { repository.blob(config) }

  it { expect(blob).to respond_to(:repository) }
  it { expect(blob).to delegate_method(:registry).to(:repository) }
  it { expect(blob).to delegate_method(:client).to(:repository) }

  context '#path' do
    subject { blob.path }

    it { is_expected.to eq('example.com/group/test@sha256:0123456789012345') }
  end

  context '#digest' do
    subject { blob.digest }

    it { is_expected.to eq(digest) }
  end

  context '#type' do
    subject { blob.type }

    it { is_expected.to eq('binary') }
  end

  context '#revision' do
    subject { blob.revision }

    it { is_expected.to eq('0123456789012345') }
  end

  context '#short_revision' do
    subject { blob.short_revision }

    it { is_expected.to eq('012345678') }
  end

  context '#delete' do
    before do
      stub_request(:delete, 'http://example.com/v2/group/test/blobs/sha256:0123456789012345').
        to_return(status: 200)
    end

    subject { blob.delete }

    it { is_expected.to be_truthy }
  end

  context '#data' do
    let(:data) { '{"key":"value"}' }

    subject { blob.data }

    context 'when locally stored' do
      before do
        stub_request(:get, 'http://example.com/v2/group/test/blobs/sha256:0123456789012345').
          to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: data)
      end

      it { is_expected.to eq(data) }
    end

    context 'when externally stored' do
      before do
        stub_request(:get, 'http://example.com/v2/group/test/blobs/sha256:0123456789012345').
          with(headers: { 'Authorization' => "bearer #{token}" }).
          to_return(
            status: 307,
            headers: { 'Location' => location })
      end

      context 'for a valid address' do
        let(:location) { 'http://external.com/blob/file' }

        before do
          stub_request(:get, location).
            with(headers: { 'Authorization' => nil }).
            to_return(
              status: 200,
              headers: { 'Content-Type' => 'application/json' },
              body: data)
        end

        it { is_expected.to eq(data) }
      end

      context 'for invalid file' do
        let(:location) { 'file:///etc/passwd' }

        it { expect{ subject }.to raise_error(ArgumentError, 'invalid address') }
      end
    end
  end
end
