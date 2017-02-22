require 'spec_helper'

describe ContainerRegistry::Repository do
  let(:registry) { ContainerRegistry::Registry.new('http://example.com') }
  let(:repository) { registry.repository('group/test') }

  it { expect(repository).to respond_to(:registry) }
  it { expect(repository).to delegate_method(:client).to(:registry) }
  it { expect(repository.tag('test')).not_to be_nil }

  context '#path' do
    subject { repository.path }

    it { is_expected.to eq('example.com/group/test') }
  end

  context 'manifest processing' do
    before do
      stub_request(:get, 'http://example.com/v2/group/test/tags/list').
        with(headers: { 'Accept' => 'application/vnd.docker.distribution.manifest.v2+json' }).
        to_return(
          status: 200,
          body: JSON.dump(tags: ['test']),
          headers: { 'Content-Type' => 'application/json' })
    end

    context '#manifest' do
      subject { repository.manifest }

      it { is_expected.not_to be_nil }
    end

    context '#valid?' do
      subject { repository.valid? }

      it { is_expected.to be_truthy }
    end

    context '#tags' do
      subject { repository.tags }

      it { is_expected.not_to be_empty }
    end
  end

  context '#delete_tags' do
    let(:tag) { ContainerRegistry::Tag.new(repository, 'tag') }

    before { expect(repository).to receive(:tags).twice.and_return([tag]) }

    subject { repository.delete_tags }

    context 'succeeds' do
      before { expect(tag).to receive(:delete).and_return(true) }

      it { is_expected.to be_truthy }
    end

    context 'any fails' do
      before { expect(tag).to receive(:delete).and_return(false) }

      it { is_expected.to be_falsey }
    end
  end
end
