# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OnboardingProgressService do
  describe '#execute' do
    let(:namespace) { create(:namespace, parent: root_namespace) }
    let(:root_namespace) { nil }
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
      let(:root_namespace) { build(:namespace) }

      before do
        OnboardingProgress.onboard(root_namespace)
      end

      it 'registers a namespace onboarding progress action for the root namespace' do
        execute_service

        expect(OnboardingProgress.completed?(root_namespace, :subscription_created)).to eq(true)
      end
    end

    context 'when no namespace is passed' do
      let(:namespace) { nil }

      it 'does not register a namespace onboarding progress action' do
        execute_service

        expect(OnboardingProgress.completed?(root_namespace, :subscription_created)).to be(nil)
      end
    end
  end
end
