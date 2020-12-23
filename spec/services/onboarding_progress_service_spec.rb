# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OnboardingProgressService do
  describe '#execute' do
    let(:namespace) { create(:namespace, parent: root_namespace) }
    let(:root_namespace) { nil }
    let(:action) { :namespace_action }

    subject(:execute_service) { described_class.new(namespace).execute(action: :subscription_created) }

    context 'when the namespace is a root' do
      it 'records a namespace onboarding progress action fot the given namespace' do
        expect(NamespaceOnboardingAction).to receive(:create_action)
          .with(namespace, :subscription_created).and_call_original

        expect { execute_service }.to change(NamespaceOnboardingAction, :count).by(1)
      end
    end

    context 'when the namespace is not the root' do
      let(:root_namespace) { build(:namespace) }

      it 'records a namespace onboarding progress action for the root namespace' do
        expect(NamespaceOnboardingAction).to receive(:create_action)
          .with(root_namespace, :subscription_created).and_call_original

        expect { execute_service }.to change(NamespaceOnboardingAction, :count).by(1)
      end
    end

    context 'when no namespace is passed' do
      let(:namespace) { nil }

      it 'does not record a namespace onboarding progress action' do
        expect(NamespaceOnboardingAction).not_to receive(:create_action)

        execute_service
      end
    end
  end
end
