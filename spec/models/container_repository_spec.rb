require 'spec_helper'

describe ContainerRepository do
  let(:group) { create(:group, name: 'group') }
  let(:project) { create(:project, path: 'test', group: group) }

  let(:container_repository) do
    create(:container_repository, name: 'my_image', project: project)
  end

  before do
    stub_container_registry_config(enabled: true,
                                   api_url: 'http://registry.gitlab',
                                   host_port: 'registry.gitlab')

    stub_request(:get, 'http://registry.gitlab/v2/group/test/my_image/tags/list')
      .with(headers: {
        'Accept' => 'application/vnd.docker.distribution.manifest.v2+json' })
      .to_return(
         status: 200,
         body: JSON.dump(tags: ['test_tag']),
         headers: { 'Content-Type' => 'application/json' })
  end

  describe 'associations' do
    it 'belongs to the project' do
      expect(container_repository).to belong_to(:project)
    end
  end

  describe '#tag' do
    it 'has a test tag' do
      expect(container_repository.tag('test')).not_to be_nil
    end
  end

  describe '#path' do
    it 'returns a full path to the repository' do
      expect(container_repository.path).to eq('group/test/my_image')
    end
  end

  describe '#manifest' do
    subject { container_repository.manifest }

    it { is_expected.not_to be_nil }
  end

  describe '#valid?' do
    subject { container_repository.valid? }

    it { is_expected.to be_truthy }
  end

  describe '#tags' do
    subject { container_repository.tags }

    it { is_expected.not_to be_empty }
  end

  # TODO, improve these specs
  #
  describe '#delete_tags' do
    let(:tag) { ContainerRegistry::Tag.new(container_repository, 'tag') }

    before do
      allow(container_repository).to receive(:tags).twice.and_return([tag])
      allow(tag).to receive(:digest)
        .and_return('sha256:4c8e63ca4cb663ce6c688cb06f1c3672a172b088dac5b6d7ad7d49cd620d85cf')
    end

    context 'when action succeeds' do
      before do
        allow(container_repository.client)
          .to receive(:delete_repository_tag)
          .and_return(true)
      end

      it 'returns status that indicates success' do
        expect(container_repository.delete_tags).to be_truthy
      end
    end

    context 'when action fails' do
      before do
        allow(container_repository.client)
          .to receive(:delete_repository_tag)
          .and_return(false)
      end

      it 'returns status that indicates failure' do
        expect(container_repository.delete_tags).to be_falsey
      end
    end
  end
end
