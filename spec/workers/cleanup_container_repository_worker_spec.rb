# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CleanupContainerRepositoryWorker, :clean_gitlab_redis_shared_state, feature_category: :container_registry do
  let(:repository) { create(:container_repository) }
  let(:project) { repository.project }
  let(:user) { project.first_owner }

  subject { described_class.new }

  describe '#perform' do
    let(:service) { instance_double(Projects::ContainerRepository::CleanupTagsService) }

    context 'bulk delete api' do
      let(:params) { { key: 'value' } }

      it 'executes the destroy service' do
        expect(Projects::ContainerRepository::CleanupTagsService).to receive(:new)
          .with(container_repository: repository, current_user: user, params: params)
          .and_return(service)
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
    end
  end
end
