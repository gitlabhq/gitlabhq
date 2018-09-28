# frozen_string_literal: true

require 'spec_helper'

describe DeleteContainerRepositoryWorker do
  let(:registry) { create(:container_repository) }
  let(:project) { registry.project }
  let(:user) { project.owner }

  subject { described_class.new }

  describe '#perform' do
    it 'executes the destroy service' do
      service = instance_double(Projects::ContainerRepository::DestroyService)
      expect(service).to receive(:execute)
      expect(Projects::ContainerRepository::DestroyService).to receive(:new).with(project, user).and_return(service)

      subject.perform(user.id, registry.id)
    end

    it 'does not raise error when user could not be found' do
      expect do
        subject.perform(-1, registry.id)
      end.not_to raise_error
    end

    it 'does not raise error when registry could not be found' do
      expect do
        subject.perform(user.id, -1)
      end.not_to raise_error
    end
  end
end
