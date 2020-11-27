# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceOnboardingAction do
  let(:namespace) { build(:namespace) }

  it { is_expected.to belong_to :namespace }

  describe '.completed?' do
    let(:action) { :subscription_created }

    subject { described_class.completed?(namespace, action) }

    context 'action created for the namespace' do
      before do
        create(:namespace_onboarding_action, namespace: namespace, action: action)
      end

      it { is_expected.to eq(true) }
    end

    context 'action created for another namespace' do
      before do
        create(:namespace_onboarding_action, namespace: build(:namespace), action: action)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '.create_action' do
    let(:action) { :subscription_created }

    subject(:create_action) { described_class.create_action(namespace, action) }

    it 'creates the action for the namespace just once' do
      expect { create_action }.to change { count_namespace_actions }.by(1)

      expect { create_action }.to change { count_namespace_actions }.by(0)
    end

    def count_namespace_actions
      described_class.where(namespace: namespace, action: action).count
    end
  end
end
