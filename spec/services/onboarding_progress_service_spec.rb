# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OnboardingProgressService do
  describe '.async' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:action) { :git_pull }

    subject(:execute_service) { described_class.async(namespace.id).execute(action: action) }

    context 'when not onboarded' do
      it 'does not schedule a worker' do
        expect(Namespaces::OnboardingProgressWorker).not_to receive(:perform_async)

        execute_service
      end
    end

    context 'when onboarded' do
      before do
        OnboardingProgress.onboard(namespace)
      end

      context 'when action is already completed' do
        before do
          OnboardingProgress.register(namespace, action)
        end

        it 'does not schedule a worker' do
          expect(Namespaces::OnboardingProgressWorker).not_to receive(:perform_async)

          execute_service
        end
      end

      context 'when action is not yet completed' do
        it 'schedules a worker' do
          expect(Namespaces::OnboardingProgressWorker).to receive(:perform_async)

          execute_service
        end
      end
    end
  end

  describe '#execute' do
    let(:namespace) { create(:namespace) }
    let(:action) { :namespace_action }

    subject(:execute_service) { described_class.new(namespace).execute(action: :subscription_created) }

    context 'when the namespace is a root' do
      before do
        OnboardingProgress.onboard(namespace)
      end

      it 'registers a namespace onboarding progress action for the given namespace' do
        execute_service

        expect(OnboardingProgress.completed?(namespace, :subscription_created)).to eq(true)
      end
    end

    context 'when the namespace is not the root' do
      let(:group) { create(:group, :nested) }

      before do
        OnboardingProgress.onboard(group)
      end

      it 'does not register a namespace onboarding progress action' do
        execute_service

        expect(OnboardingProgress.completed?(group, :subscription_created)).to be(nil)
      end
    end

    context 'when no namespace is passed' do
      let(:namespace) { nil }

      it 'does not register a namespace onboarding progress action' do
        execute_service

        expect(OnboardingProgress.completed?(namespace, :subscription_created)).to be(nil)
      end
    end
  end
end
