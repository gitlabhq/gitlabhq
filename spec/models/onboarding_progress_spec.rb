# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OnboardingProgress do
  let(:namespace) { create(:namespace) }
  let(:action) { :subscription_created }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
  end

  describe 'validations' do
    describe 'namespace_is_root_namespace' do
      subject(:onboarding_progress) { build(:onboarding_progress, namespace: namespace)}

      context 'when associated namespace is root' do
        it { is_expected.to be_valid }
      end

      context 'when associated namespace is not root' do
        let(:namespace) { build(:group, :nested) }

        it 'is invalid' do
          expect(onboarding_progress).to be_invalid
          expect(onboarding_progress.errors[:namespace]).to include('must be a root namespace')
        end
      end
    end
  end

  describe '.onboard' do
    subject(:onboard) { described_class.onboard(namespace) }

    it 'adds a record for the namespace' do
      expect { onboard }.to change(described_class, :count).from(0).to(1)
    end

    context 'when not given a namespace' do
      let(:namespace) { nil }

      it 'does not add a record for the namespace' do
        expect { onboard }.not_to change(described_class, :count).from(0)
      end
    end

    context 'when not given a root namespace' do
      let(:namespace) { create(:namespace, parent: build(:namespace)) }

      it 'does not add a record for the namespace' do
        expect { onboard }.not_to change(described_class, :count).from(0)
      end
    end
  end

  describe '.register' do
    subject(:register_action) { described_class.register(namespace, action) }

    context 'when the namespace was onboarded' do
      before do
        described_class.onboard(namespace)
      end

      it 'registers the action for the namespace' do
        expect { register_action }.to change { described_class.completed?(namespace, action) }.from(false).to(true)
      end

      context 'when the action does not exist' do
        let(:action) { :foo }

        it 'does not register the action for the namespace' do
          expect { register_action }.not_to change { described_class.completed?(namespace, action) }.from(nil)
        end
      end
    end

    context 'when the namespace was not onboarded' do
      it 'does not register the action for the namespace' do
        expect { register_action }.not_to change { described_class.completed?(namespace, action) }.from(false)
      end
    end
  end

  describe '.completed?' do
    subject { described_class.completed?(namespace, action) }

    context 'when the namespace has not yet been onboarded' do
      it { is_expected.to eq(false) }
    end

    context 'when the namespace has been onboarded but not registered the action yet' do
      before do
        described_class.onboard(namespace)
      end

      it { is_expected.to eq(false) }

      context 'when the action has been registered' do
        before do
          described_class.register(namespace, action)
        end

        it { is_expected.to eq(true) }
      end
    end
  end
end
