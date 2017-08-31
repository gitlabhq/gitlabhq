require 'spec_helper'

describe ContainerRepository do
  let(:group) { create(:group, name: 'group') }
  let(:project) { create(:project, path: 'test', group: group) }

  let(:repository) do
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
      expect(repository).to belong_to(:project)
    end
  end

  describe '#tag' do
    it 'has a test tag' do
      expect(repository.tag('test')).not_to be_nil
    end
  end

  describe '#path' do
    context 'when project path does not contain uppercase letters' do
      it 'returns a full path to the repository' do
        expect(repository.path).to eq('group/test/my_image')
      end
    end

    context 'when path contains uppercase letters' do
      let(:project) { create(:project, :repository, path: 'MY_PROJECT', group: group) }

      it 'returns a full path without capital letters' do
        expect(repository.path).to eq('group/my_project/my_image')
      end
    end
  end

  describe '#manifest' do
    it 'returns non-empty manifest' do
      expect(repository.manifest).not_to be_nil
    end
  end

  describe '#valid?' do
    it 'is a valid repository' do
      expect(repository).to be_valid
    end
  end

  describe '#tags' do
    it 'returns non-empty tags list' do
      expect(repository.tags).not_to be_empty
    end
  end

  describe '#has_tags?' do
    it 'has tags' do
      expect(repository).to have_tags
    end
  end

  describe '#delete_tags!' do
    let(:repository) do
      create(:container_repository, name: 'my_image',
                                    tags: %w[latest rc1],
                                    project: project)
    end

    context 'when action succeeds' do
      it 'returns status that indicates success' do
        expect(repository.client)
          .to receive(:delete_repository_tag)
          .and_return(true)

        expect(repository.delete_tags!).to be_truthy
      end
    end

    context 'when action fails' do
      it 'returns status that indicates failure' do
        expect(repository.client)
          .to receive(:delete_repository_tag)
          .and_return(false)

        expect(repository.delete_tags!).to be_falsey
      end
    end
  end

  describe '#location' do
    context 'when registry is running on a custom port' do
      before do
        stub_container_registry_config(enabled: true,
                                       api_url: 'http://registry.gitlab:5000',
                                       host_port: 'registry.gitlab:5000')
      end

      it 'returns a full location of the repository' do
        expect(repository.location)
          .to eq 'registry.gitlab:5000/group/test/my_image'
      end
    end
  end

  describe '#root_repository?' do
    context 'when repository is a root repository' do
      let(:repository) { create(:container_repository, :root) }

      it 'returns true' do
        expect(repository).to be_root_repository
      end
    end

    context 'when repository is not a root repository' do
      it 'returns false' do
        expect(repository).not_to be_root_repository
      end
    end
  end

  describe '.build_from_path' do
    let(:registry_path) do
      ContainerRegistry::Path.new(project.full_path + '/some/image')
    end

    let(:repository) do
      described_class.build_from_path(registry_path)
    end

    it 'fabricates repository assigned to a correct project' do
      expect(repository.project).to eq project
    end

    it 'fabricates repository with a correct name' do
      expect(repository.name).to eq 'some/image'
    end

    it 'is not persisted' do
      expect(repository).not_to be_persisted
    end
  end

  describe '.create_from_path!' do
    let(:repository) do
      described_class.create_from_path!(ContainerRegistry::Path.new(path))
    end

    let(:repository_path) { ContainerRegistry::Path.new(path) }

    context 'when received multi-level repository path' do
      let(:path) { project.full_path + '/some/image' }

      it 'fabricates repository assigned to a correct project' do
        expect(repository.project).to eq project
      end

      it 'fabricates repository with a correct name' do
        expect(repository.name).to eq 'some/image'
      end
    end

    context 'when path is too long' do
      let(:path) do
        project.full_path + '/a/b/c/d/e/f/g/h/i/j/k/l/n/o/p/s/t/u/x/y/z'
      end

      it 'does not create repository and raises error' do
        expect { repository }.to raise_error(
          ContainerRegistry::Path::InvalidRegistryPathError)
      end
    end

    context 'when received multi-level repository with nested groups' do
      let(:group) { create(:group, :nested, name: 'nested') }
      let(:path) { project.full_path + '/some/image' }

      it 'fabricates repository assigned to a correct project' do
        expect(repository.project).to eq project
      end

      it 'fabricates repository with a correct name' do
        expect(repository.name).to eq 'some/image'
      end

      it 'has path including a nested group' do
        expect(repository.path).to include 'nested/test/some/image'
      end
    end

    context 'when received root repository path' do
      let(:path) { project.full_path }

      it 'fabricates repository assigned to a correct project' do
        expect(repository.project).to eq project
      end

      it 'fabricates repository with an empty name' do
        expect(repository.name).to be_empty
      end
    end
  end

  describe '.build_root_repository' do
    let(:repository) do
      described_class.build_root_repository(project)
    end

    it 'fabricates a root repository object' do
      expect(repository).to be_root_repository
    end

    it 'assignes it to the correct project' do
      expect(repository.project).to eq project
    end

    it 'does not persist it' do
      expect(repository).not_to be_persisted
    end
  end
end
