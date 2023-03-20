# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeleteContainerRepositoryWorker, feature_category: :container_registry do
  let_it_be(:repository) { create(:container_repository) }

  let(:project) { repository.project }
  let(:user) { project.first_owner }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform) { worker.perform(user.id, repository.id) }

    it 'is a no op' do
      expect { subject }.to not_change { ContainerRepository.count }
    end
  end
end
