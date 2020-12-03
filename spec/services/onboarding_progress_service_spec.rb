# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OnboardingProgressService do
  describe '#execute' do
    let_it_be(:namespace) { build(:namespace) }
    let(:action) { :namespace_action }

    subject(:execute_service) { described_class.new(namespace).execute(action: action) }

    it 'records a namespace onboarding progress action' do
      expect(NamespaceOnboardingAction).to receive(:create_action)
            .with(namespace, :namespace_action)

      subject
    end
  end
end
