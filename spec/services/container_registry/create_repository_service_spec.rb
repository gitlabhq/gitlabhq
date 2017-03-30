require 'spec_helper'

describe ContainerRegistry::CreateRepositoryService, '#execute' do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  let(:path) do
    ContainerRegistry::Path.new("#{project.full_path}/my/image")
  end

  let(:service) { described_class.new(project, user) }

  before do
    stub_container_registry_config(enabled: true)
  end

  context 'when container repository already exists' do
    before do
      create(:container_repository, project: project, name: 'my/image')
    end

    it 'does not create container repository again' do
      expect { service.execute(path) }
        .to raise_error(Gitlab::Access::AccessDeniedError)
        .and change { ContainerRepository.count }.by(0)
    end
  end

  context 'when repository is created by an user' do
    context 'when user has no ability to create a repository' do
      it 'does not create a new container repository' do
        expect { service.execute(path) }
          .to raise_error(Gitlab::Access::AccessDeniedError)
          .and change { ContainerRepository.count }.by(0)
      end
    end

    context 'when user has ability do create a repository' do
      before do
        project.add_developer(user)
      end

      it 'creates a new container repository' do
        expect { service.execute(path) }
          .to change { project.container_repositories.count }.by(1)
      end
    end
  end

  context 'when repository is created by a legacy pipeline trigger' do
    let(:user) { nil }

    context 'when repository path matches authenticated project' do
      it 'creates a new container repository' do
        expect { service.execute(path) }
          .to change { project.container_repositories.count }.by(1)
      end
    end

    context 'when repository path does not match authenticated project' do
      let(:private_project) { create(:empty_project, :private) }

      let(:path) do
        ContainerRegistry::Path.new("#{private_project.full_path}/my/image")
      end

      it 'does not create a new container repository' do
        expect { service.execute(path) }
          .to raise_error(Gitlab::Access::AccessDeniedError)
          .and change { ContainerRepository.count }.by(0)
      end
    end
  end
end
