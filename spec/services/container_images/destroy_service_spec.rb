require 'spec_helper'

describe ContainerImages::DestroyService, services: true do
  describe '#execute' do
    let(:user)    { create(:user) }
    let(:container_image) { create(:container_image, name: '') }
    let(:project) { create(:project, path: 'test', namespace: user.namespace, container_images: [container_image]) }
    let(:example_host) { 'example.com' }
    let(:registry_url) { 'http://' + example_host }

    it { expect(container_image).to be_valid }
    it { expect(project.container_images).not_to be_empty }

    context 'when container image has tags' do
      before do
        project.team << [user, :master]
      end

      it 'removes all tags before destroy' do
        service = described_class.new(project, user)

        expect(container_image).to receive(:delete_tags).and_return(true)
        expect { service.execute(container_image) }.to change(project.container_images, :count).by(-1)
      end

      it 'fails when tags are not removed' do
        service = described_class.new(project, user)

        expect(container_image).to receive(:delete_tags).and_return(false)
        expect { service.execute(container_image) }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end
  end
end
