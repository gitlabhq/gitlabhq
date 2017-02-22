require 'spec_helper'

describe ContainerRegistry::Tag do
  let(:registry) { ContainerRegistry::Registry.new('http://example.com') }
  let(:repository) { registry.repository('group/test') }
  let(:tag) { repository.tag('tag') }
  let(:headers) { { 'Accept' => 'application/vnd.docker.distribution.manifest.v2+json' } }

  it { expect(tag).to respond_to(:repository) }
  it { expect(tag).to delegate_method(:registry).to(:repository) }
  it { expect(tag).to delegate_method(:client).to(:repository) }

  context '#path' do
    subject { tag.path }

    it { is_expected.to eq('example.com/group/test:tag') }
  end

  context 'manifest processing' do
    context 'schema v1' do
      before do
        stub_request(:get, 'http://example.com/v2/group/test/manifests/tag').
          with(headers: headers).
          to_return(
            status: 200,
            body: File.read(Rails.root + 'spec/fixtures/container_registry/tag_manifest_1.json'),
            headers: { 'Content-Type' => 'application/vnd.docker.distribution.manifest.v1+prettyjws' })
      end

      context '#layers' do
        subject { tag.layers }

        it { expect(subject.length).to eq(1) }
      end

      context '#total_size' do
        subject { tag.total_size }

        it { is_expected.to be_nil }
      end

      context 'config processing' do
        context '#config' do
          subject { tag.config }

          it { is_expected.to be_nil }
        end

        context '#created_at' do
          subject { tag.created_at }

          it { is_expected.to be_nil }
        end
      end
    end

    context 'schema v2' do
      before do
        stub_request(:get, 'http://example.com/v2/group/test/manifests/tag').
          with(headers: headers).
          to_return(
            status: 200,
            body: File.read(Rails.root + 'spec/fixtures/container_registry/tag_manifest.json'),
            headers: { 'Content-Type' => 'application/vnd.docker.distribution.manifest.v2+json' })
      end

      context '#layers' do
        subject { tag.layers }

        it { expect(subject.length).to eq(1) }
      end

      context '#total_size' do
        subject { tag.total_size }

        it { is_expected.to eq(2319870) }
      end

      context 'config processing' do
        shared_examples 'a processable' do
          context '#config' do
            subject { tag.config }

            it { is_expected.not_to be_nil }
          end

          context '#created_at' do
            subject { tag.created_at }

            it { is_expected.not_to be_nil }
          end
        end

        context 'when locally stored' do
          before do
            stub_request(:get, 'http://example.com/v2/group/test/blobs/sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac').
              with(headers: { 'Accept' => 'application/octet-stream' }).
              to_return(
                status: 200,
                body: File.read(Rails.root + 'spec/fixtures/container_registry/config_blob.json'))
          end

          it_behaves_like 'a processable'
        end

        context 'when externally stored' do
          before do
            stub_request(:get, 'http://example.com/v2/group/test/blobs/sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac').
              with(headers: { 'Accept' => 'application/octet-stream' }).
              to_return(
                status: 307,
                headers: { 'Location' => 'http://external.com/blob/file' })

            stub_request(:get, 'http://external.com/blob/file').
              to_return(
                status: 200,
                body: File.read(Rails.root + 'spec/fixtures/container_registry/config_blob.json'))
          end

          it_behaves_like 'a processable'
        end
      end
    end
  end

  context 'manifest digest' do
    before do
      stub_request(:head, 'http://example.com/v2/group/test/manifests/tag').
        with(headers: headers).
        to_return(status: 200, headers: { 'Docker-Content-Digest' => 'sha256:digest' })
    end

    context '#digest' do
      subject { tag.digest }

      it { is_expected.to eq('sha256:digest') }
    end

    context '#delete' do
      before do
        stub_request(:delete, 'http://example.com/v2/group/test/manifests/sha256:digest').
          with(headers: headers).
          to_return(status: 200)
      end

      subject { tag.delete }

      it { is_expected.to be_truthy }
    end
  end
end
