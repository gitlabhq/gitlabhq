require 'spec_helper'

describe ContainerImages::DestroyService, services: true do
  describe '#execute' do
    let(:user)    { create(:user) }
    let(:container_repository) { create(:container_repository, name: '') }
    let(:project) { create(:project, path: 'test', namespace: user.namespace, container_repositorys: [container_repository]) }
    let(:example_host) { 'example.com' }
    let(:registry_url) { 'http://' + example_host }

    it { expect(container_repository).to be_valid }
    it { expect(project.container_repositorys).not_to be_empty }

    context 'when container image has tags' do
      before do
        project.team << [user, :master]
      end

      it 'removes all tags before destroy' do
        service = described_class.new(project, user)

        expect(container_repository).to receive(:delete_tags).and_return(true)
        expect { service.execute(container_repository) }.to change(project.container_repositorys, :count).by(-1)
      end

      it 'fails when tags are not removed' do
        service = described_class.new(project, user)

        expect(container_repository).to receive(:delete_tags).and_return(false)
        expect { service.execute(container_repository) }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end
  end
end
