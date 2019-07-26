# frozen_string_literal: true

require 'spec_helper'

describe ContainerRegistry::Tag do
  let(:group) { create(:group, name: 'group') }
  let(:project) { create(:project, path: 'test', group: group) }

  let(:repository) do
    create(:container_repository, name: '', project: project)
  end

  let(:headers) do
    { 'Accept' => ContainerRegistry::Client::ACCEPTED_TYPES.join(', ') }
  end

  let(:tag) { described_class.new(repository, 'tag') }

  before do
    stub_container_registry_config(enabled: true,
                                   api_url: 'http://registry.gitlab',
                                   host_port: 'registry.gitlab')
  end

  it { expect(tag).to respond_to(:repository) }
  it { expect(tag).to delegate_method(:registry).to(:repository) }
  it { expect(tag).to delegate_method(:client).to(:repository) }

  describe '#path' do
    context 'when tag belongs to zero-level repository' do
      let(:repository) do
        create(:container_repository, name: '',
                                      tags: %w[rc1],
                                      project: project)
      end

      it 'returns path to the image' do
        expect(tag.path).to eq('group/test:tag')
      end
    end

    context 'when tag belongs to first-level repository' do
      let(:repository) do
        create(:container_repository, name: 'my_image',
                                      tags: %w[tag],
                                      project: project)
      end

      it 'returns path to the image' do
        expect(tag.path).to eq('group/test/my_image:tag')
      end
    end
  end

  describe '#location' do
    it 'returns a full location of the tag' do
      expect(tag.location)
        .to eq 'registry.gitlab/group/test:tag'
    end
  end

  context 'manifest processing' do
    context 'schema v1' do
      before do
        stub_request(:get, 'http://registry.gitlab/v2/group/test/manifests/tag')
          .with(headers: headers)
          .to_return(
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
        stub_request(:get, 'http://registry.gitlab/v2/group/test/manifests/tag')
          .with(headers: headers)
          .to_return(
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
            stub_request(:get, 'http://registry.gitlab/v2/group/test/blobs/sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac')
              .with(headers: { 'Accept' => 'application/octet-stream' })
              .to_return(
                status: 200,
                body: File.read(Rails.root + 'spec/fixtures/container_registry/config_blob.json'))
          end

          it_behaves_like 'a processable'
        end

        context 'when externally stored' do
          before do
            stub_request(:get, 'http://registry.gitlab/v2/group/test/blobs/sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac')
              .with(headers: { 'Accept' => 'application/octet-stream' })
              .to_return(
                status: 307,
                headers: { 'Location' => 'http://external.com/blob/file' })

            stub_request(:get, 'http://external.com/blob/file')
              .to_return(
                status: 200,
                body: File.read(Rails.root + 'spec/fixtures/container_registry/config_blob.json'))
          end

          it_behaves_like 'a processable'
        end
      end
    end
  end

  context 'with stubbed digest' do
    before do
      stub_request(:head, 'http://registry.gitlab/v2/group/test/manifests/tag')
        .with(headers: headers)
        .to_return(status: 200, headers: { 'Docker-Content-Digest' => 'sha256:digest' })
    end

    describe '#digest' do
      it 'returns a correct tag digest' do
        expect(tag.digest).to eq 'sha256:digest'
      end
    end

    describe '#delete' do
      before do
        stub_request(:delete, 'http://registry.gitlab/v2/group/test/manifests/sha256:digest')
          .with(headers: headers)
          .to_return(status: 200)
      end

      it 'correctly deletes the tag' do
        expect(tag.delete).to be_truthy
      end
    end
  end
end
