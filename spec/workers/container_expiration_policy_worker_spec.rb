# frozen_string_literal: true

require 'spec_helper'

describe ContainerExpirationPolicyWorker do
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
  end
end
