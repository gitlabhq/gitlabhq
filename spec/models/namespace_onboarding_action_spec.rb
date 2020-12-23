# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceOnboardingAction do
  let(:namespace) { create(:namespace) }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:action) }
  end

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

    context 'when the namespace is created outside the monitoring window' do
      let(:namespace) { create(:namespace, created_at: (NamespaceOnboardingAction::MONITORING_WINDOW + 1.day).ago) }

      it 'does not create an action for the namespace' do
        expect { create_action }.not_to change { count_namespace_actions }
      end

      context 'when an action has already been recorded for the namespace' do
        before do
          described_class.create!(namespace: namespace, action: :git_write)
        end

        it 'creates an action for the namespace' do
          expect { create_action }.to change { count_namespace_actions }.by(1)
        end
      end
    end

    context 'when the namespace is not a root' do
      let(:namespace) { create(:namespace, parent: build(:namespace)) }

      it 'does not create an action for the namespace' do
        expect { create_action }.not_to change { count_namespace_actions }
      end
    end

    def count_namespace_actions
      described_class.where(namespace: namespace, action: action).count
    end
  end
end
