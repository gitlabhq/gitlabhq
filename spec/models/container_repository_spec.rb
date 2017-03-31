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
      .with(headers: { 'Accept' => 'application/vnd.docker.distribution.manifest.v2+json' })
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

  describe '#delete_tags!' do
    let(:container_repository) do
      create(:container_repository, name: 'my_image',
                                    tags: %w[latest rc1],
                                    project: project)
    end

    context 'when action succeeds' do
      it 'returns status that indicates success' do
        expect(container_repository.client)
          .to receive(:delete_repository_tag)
          .and_return(true)

        expect(container_repository.delete_tags!).to be_truthy
      end
    end

    context 'when action fails' do
      it 'returns status that indicates failure' do
        expect(container_repository.client)
          .to receive(:delete_repository_tag)
          .and_return(false)

        expect(container_repository.delete_tags!).to be_falsey
      end
    end
  end

  describe '#from_repository_path' do
    context 'when received multi-level repository path' do
      let(:repository) do
        described_class.from_repository_path('group/test/some/image/name')
      end

      pending 'fabricates object within a correct project' do
        expect(repository.project).to eq project
      end

      pending 'it fabricates project with a correct name' do
        expect(repository.name).to eq 'some/image/name'
      end
    end

    context 'when path contains too many nodes' do
    end

    context 'when received multi-level repository with nested groups' do
    end

    context 'when received root repository path' do
    end
  end
end
