# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicyService do
  let_it_be(:user) { create(:user) }
  let_it_be(:container_expiration_policy) { create(:container_expiration_policy, :runnable) }
  let(:project) { container_expiration_policy.project }
  let(:container_repository) { create(:container_repository, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    subject { described_class.new(project, user).execute(container_expiration_policy) }

    it 'kicks off a cleanup worker for the container repository' do
      expect(CleanupContainerRepositoryWorker).to receive(:perform_async)
        .with(nil, container_repository.id, hash_including(container_expiration_policy: true))

      subject
    end

    it 'sets next_run_at on the container_expiration_policy' do
      subject

      expect(container_expiration_policy.next_run_at).to be > Time.zone.now
    end

    context 'with an invalid container expiration policy' do
      before do
        allow(container_expiration_policy).to receive(:valid?).and_return(false)
      end

      it 'disables it' do
        expect(container_expiration_policy).not_to receive(:schedule_next_run!)
        expect(CleanupContainerRepositoryWorker).not_to receive(:perform_async)

        expect { subject }
          .to change { container_expiration_policy.reload.enabled }.from(true).to(false)
          .and raise_error(ContainerExpirationPolicyService::InvalidPolicyError)
      end
    end
  end
end
