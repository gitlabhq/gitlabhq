# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicyWorker do
  include ExclusiveLeaseHelpers

  subject { described_class.new.perform }

  RSpec.shared_examples 'not executing any policy' do
    it 'does not run any policy' do
      expect(ContainerExpirationPolicyService).not_to receive(:new)

      subject
    end
  end

  context 'With no container expiration policies' do
    it_behaves_like 'not executing any policy'
  end

  context 'With container expiration policies' do
    let_it_be(:container_expiration_policy, reload: true) { create(:container_expiration_policy, :runnable) }
    let_it_be(:container_repository) { create(:container_repository, project: container_expiration_policy.project) }
    let_it_be(:user) { container_expiration_policy.project.owner }

    context 'a valid policy' do
      it 'runs the policy' do
        service = instance_double(ContainerExpirationPolicyService, execute: true)

        expect(ContainerExpirationPolicyService)
          .to receive(:new).with(container_expiration_policy.project, user).and_return(service)

        subject
      end
    end

    context 'a disabled policy' do
      before do
        container_expiration_policy.disable!
      end

      it_behaves_like 'not executing any policy'
    end

    context 'a policy that is not due for a run' do
      before do
        container_expiration_policy.update_column(:next_run_at, 2.minutes.from_now)
      end

      it_behaves_like 'not executing any policy'
    end

    context 'a policy linked to no container repository' do
      before do
        container_expiration_policy.container_repositories.delete_all
      end

      it_behaves_like 'not executing any policy'
    end

    context 'an invalid policy' do
      before do
        container_expiration_policy.update_column(:name_regex, '*production')
      end

      it 'runs the policy and tracks an error' do
        expect(ContainerExpirationPolicyService)
          .to receive(:new).with(container_expiration_policy.project, user).and_call_original
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(instance_of(ContainerExpirationPolicyService::InvalidPolicyError), container_expiration_policy_id: container_expiration_policy.id)

        expect { subject }.to change { container_expiration_policy.reload.enabled }.from(true).to(false)
      end
    end
  end
end
