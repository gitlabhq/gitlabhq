require 'spec_helper'

describe ContainerImage do
  let(:group) { create(:group, name: 'group') }
  let(:project) { create(:project, path: 'test', group: group) }
  let(:example_host) { 'example.com' }
  let(:registry_url) { 'http://' + example_host }
  let(:container_image) { create(:container_image, name: '', project: project, stubbed: false) }

  before do
    stub_container_registry_config(enabled: true, api_url: registry_url, host_port: example_host)
    stub_request(:get, 'http://example.com/v2/group/test/tags/list').
      with(headers: { 'Accept' => 'application/vnd.docker.distribution.manifest.v2+json' }).
      to_return(
        status: 200,
        body: JSON.dump(tags: ['test']),
        headers: { 'Content-Type' => 'application/json' })
  end

  it { expect(container_image).to respond_to(:project) }
  it { expect(container_image).to delegate_method(:container_registry).to(:project) }
  it { expect(container_image).to delegate_method(:client).to(:container_registry) }
  it { expect(container_image.tag('test')).not_to be_nil }

  context '#path' do
    subject { container_image.path }

    it { is_expected.to eq('example.com/group/test') }
  end

  context 'manifest processing' do
    context '#manifest' do
      subject { container_image.manifest }

      it { is_expected.not_to be_nil }
    end

    context '#valid?' do
      subject { container_image.valid? }

      it { is_expected.to be_truthy }
    end

    context '#tags' do
      subject { container_image.tags }

      it { is_expected.not_to be_empty }
    end
  end

  context '#delete_tags' do
    let(:tag) { ContainerRegistry::Tag.new(container_image, 'tag') }

    before do
      expect(container_image).to receive(:tags).twice.and_return([tag])
      expect(tag).to receive(:digest).and_return('sha256:4c8e63ca4cb663ce6c688cb06f1c3672a172b088dac5b6d7ad7d49cd620d85cf')
    end

    subject { container_image.delete_tags }

    context 'succeeds' do
      before { expect(container_image.client).to receive(:delete_repository_tag).and_return(true) }

      it { is_expected.to be_truthy }
    end

    context 'any fails' do
      before { expect(container_image.client).to receive(:delete_repository_tag).and_return(false) }

      it { is_expected.to be_falsey }
    end
  end
end
