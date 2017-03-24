require 'spec_helper'

describe ContainerImages::DestroyService, '#execute', :services do
  let(:user) { create(:user) }

  let(:container_repository) do
    create(:container_repository, name: 'myimage', tags: %w[latest])
  end

  let(:project) do
    create(:project, path: 'test',
                     namespace: user.namespace,
                     container_repositories: [container_repository])
  end

  it { expect(container_repository).to be_valid }
  it { expect(project.container_repositories).not_to be_empty }

  context 'when container image has tags' do
    before do
      project.add_master(user)
    end

    it 'removes all tags before destroy' do
      service = described_class.new(project, user)

      expect(container_repository)
        .to receive(:delete_tags).and_return(true)
      expect { service.execute(container_repository) }
        .to change(project.container_repositories, :count).by(-1)
    end

    it 'fails when tags are not removed' do
      service = described_class.new(project, user)

      expect(container_repository)
        .to receive(:delete_tags).and_return(false)
      expect { service.execute(container_repository) }
        .to raise_error(ActiveRecord::RecordNotDestroyed)
    end
  end
end
