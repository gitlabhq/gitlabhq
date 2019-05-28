# frozen_string_literal: true

require 'spec_helper'

describe CleanupContainerRepositoryWorker, :clean_gitlab_redis_shared_state do
  let(:repository) { create(:container_repository) }
  let(:project) { repository.project }
  let(:user) { project.owner }
  let(:params) { { key: 'value' } }

  subject { described_class.new }

  describe '#perform' do
    let(:service) { instance_double(Projects::ContainerRepository::CleanupTagsService) }

    before do
      allow(Projects::ContainerRepository::CleanupTagsService).to receive(:new)
        .with(project, user, params).and_return(service)
    end

    it 'executes the destroy service' do
      expect(service).to receive(:execute)

      subject.perform(user.id, repository.id, params)
    end

    it 'does not raise error when user could not be found' do
      expect do
        subject.perform(-1, repository.id, params)
      end.not_to raise_error
    end

    it 'does not raise error when repository could not be found' do
      expect do
        subject.perform(user.id, -1, params)
      end.not_to raise_error
    end

    context 'when executed twice in short period' do
      it 'executes service only for the first time' do
        expect(service).to receive(:execute).once

        2.times { subject.perform(user.id, repository.id, params) }
      end
    end
  end
end
