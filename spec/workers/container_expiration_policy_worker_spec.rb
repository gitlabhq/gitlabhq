# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicyWorker do
  include ExclusiveLeaseHelpers

  subject { described_class.new.perform }

  context 'With no container expiration policies' do
    it 'Does not execute any policies' do
      expect(ContainerExpirationPolicyService).not_to receive(:new)

      subject
    end
  end

  context 'With container expiration policies' do
    context 'a valid policy' do
      let!(:container_expiration_policy) { create(:container_expiration_policy, :runnable) }
      let(:user) { container_expiration_policy.project.owner }

      it 'runs the policy' do
        service = instance_double(ContainerExpirationPolicyService, execute: true)

        expect(ContainerExpirationPolicyService)
          .to receive(:new).with(container_expiration_policy.project, user).and_return(service)

        subject
      end
    end

    context 'a disabled policy' do
      let!(:container_expiration_policy) { create(:container_expiration_policy, :runnable, :disabled) }
      let(:user) {container_expiration_policy.project.owner }

      it 'does not run the policy' do
        expect(ContainerExpirationPolicyService)
          .not_to receive(:new).with(container_expiration_policy, user)

        subject
      end
    end

    context 'a policy that is not due for a run' do
      let!(:container_expiration_policy) { create(:container_expiration_policy) }
      let(:user) {container_expiration_policy.project.owner }

      it 'does not run the policy' do
        expect(ContainerExpirationPolicyService)
          .not_to receive(:new).with(container_expiration_policy, user)

        subject
      end
    end

    context 'an invalid policy' do
      let_it_be(:container_expiration_policy) { create(:container_expiration_policy, :runnable) }
      let_it_be(:user) {container_expiration_policy.project.owner }

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
