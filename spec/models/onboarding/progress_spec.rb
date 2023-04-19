# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::Progress do
  let(:namespace) { create(:namespace) }
  let(:action) { :subscription_created }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
  end

  describe 'validations' do
    describe 'namespace_is_root_namespace' do
      subject(:onboarding_progress) { build(:onboarding_progress, namespace: namespace) }

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

  describe 'scopes' do
    describe '.incomplete_actions' do
      subject { described_class.incomplete_actions(actions) }

      let!(:no_actions_completed) { create(:onboarding_progress) }
      let!(:one_action_completed_one_action_incompleted) do
        create(:onboarding_progress, "#{action}_at" => Time.current)
      end

      context 'when given one action' do
        let(:actions) { action }

        it { is_expected.to eq [no_actions_completed] }
      end

      context 'when given an array of actions' do
        let(:actions) { [action, :git_write] }

        it { is_expected.to eq [no_actions_completed] }
      end
    end

    describe '.completed_actions' do
      subject { described_class.completed_actions(actions) }

      let!(:one_action_completed_one_action_incompleted) do
        create(:onboarding_progress, "#{action}_at" => Time.current)
      end

      let!(:both_actions_completed) do
        create(:onboarding_progress, "#{action}_at" => Time.current, git_write_at: Time.current)
      end

      context 'when given one action' do
        let(:actions) { action }

        it { is_expected.to eq [one_action_completed_one_action_incompleted, both_actions_completed] }
      end

      context 'when given an array of actions' do
        let(:actions) { [action, :git_write] }

        it { is_expected.to eq [both_actions_completed] }
      end
    end

    describe '.completed_actions_with_latest_in_range' do
      subject do
        described_class.completed_actions_with_latest_in_range(actions,
                                                               1.day.ago.beginning_of_day..1.day.ago.end_of_day)
      end

      let!(:one_action_completed_in_range_one_action_incompleted) do
        create(:onboarding_progress, "#{action}_at" => 1.day.ago.middle_of_day)
      end

      let!(:git_write_action_completed_in_range) { create(:onboarding_progress, git_write_at: 1.day.ago.middle_of_day) }
      let!(:both_actions_completed_latest_action_out_of_range) do
        create(:onboarding_progress, "#{action}_at" => 1.day.ago.middle_of_day, git_write_at: Time.current)
      end

      let!(:both_actions_completed_latest_action_in_range) do
        create(:onboarding_progress, "#{action}_at" => 1.day.ago.middle_of_day, git_write_at: 2.days.ago.middle_of_day)
      end

      context 'when given one action' do
        let(:actions) { :git_write }

        it { is_expected.to eq [git_write_action_completed_in_range] }
      end

      context 'when given an array of actions' do
        let(:actions) { [action, :git_write] }

        it { is_expected.to eq [both_actions_completed_latest_action_in_range] }
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
      let(:namespace) { create(:group, parent: build(:group)) }

      it 'does not add a record for the namespace' do
        expect { onboard }.not_to change(described_class, :count).from(0)
      end
    end
  end

  describe '.onboarding?' do
    subject(:onboarding?) { described_class.onboarding?(namespace) }

    context 'when onboarded' do
      before do
        described_class.onboard(namespace)
      end

      it { is_expected.to eq true }
    end

    context 'when not onboarding' do
      it { is_expected.to eq false }
    end
  end

  describe '.register' do
    context 'for a single action' do
      subject(:register_action) { described_class.register(namespace, action) }

      context 'when the namespace was onboarded' do
        before do
          described_class.onboard(namespace)
        end

        it 'registers the action for the namespace' do
          expect { register_action }.to change { described_class.completed?(namespace, action) }.from(false).to(true)
        end

        it 'does not override timestamp', :aggregate_failures do
          expect(described_class.find_by_namespace_id(namespace.id).subscription_created_at).to be_nil
          register_action
          expect(described_class.find_by_namespace_id(namespace.id).subscription_created_at).not_to be_nil
          expect do
            described_class.register(namespace, action)
          end.not_to change { described_class.find_by_namespace_id(namespace.id).subscription_created_at }
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

    context 'for multiple actions' do
      let(:action1) { :secure_dast_run }
      let(:action2) { :secure_dependency_scanning_run }
      let(:actions) { [action1, action2] }

      subject(:register_action) { described_class.register(namespace, actions) }

      context 'when the namespace was onboarded' do
        before do
          described_class.onboard(namespace)
        end

        it 'registers the actions for the namespace' do
          expect { register_action }.to change {
            [described_class.completed?(namespace, action1), described_class.completed?(namespace, action2)]
          }.from([false, false]).to([true, true])
        end

        it 'does not override timestamp', :aggregate_failures do
          described_class.register(namespace, [action1])
          expect(described_class.find_by_namespace_id(namespace.id).secure_dast_run_at).not_to be_nil
          expect(described_class.find_by_namespace_id(namespace.id).secure_dependency_scanning_run_at).to be_nil

          expect { described_class.register(namespace, [action1, action2]) }.not_to change {
            described_class.find_by_namespace_id(namespace.id).secure_dast_run_at
          }
          expect(described_class.find_by_namespace_id(namespace.id).secure_dependency_scanning_run_at).not_to be_nil
        end

        context 'when one of the actions does not exist' do
          let(:action2) { :foo }

          it 'does not register any action for the namespace' do
            expect { register_action }.not_to change {
              [described_class.completed?(namespace, action1), described_class.completed?(namespace, action2)]
            }.from([false, nil])
          end
        end
      end

      context 'when the namespace was not onboarded' do
        it 'does not register the action for the namespace' do
          expect { register_action }.not_to change { described_class.completed?(namespace, action1) }.from(false)
          expect do
            described_class.register(namespace, action)
          end.not_to change { described_class.completed?(namespace, action2) }.from(false)
        end
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

  describe '.not_completed?' do
    subject { described_class.not_completed?(namespace.id, action) }

    context 'when the namespace has not yet been onboarded' do
      it { is_expected.to be(false) }
    end

    context 'when the namespace has been onboarded but not registered the action yet' do
      before do
        described_class.onboard(namespace)
      end

      it { is_expected.to be(true) }

      context 'when the action has been registered' do
        before do
          described_class.register(namespace, action)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  describe '.column_name' do
    subject { described_class.column_name(action) }

    it { is_expected.to eq(:subscription_created_at) }
  end

  describe '#number_of_completed_actions' do
    subject do
      build(:onboarding_progress, actions.map { |x| { x => Time.current } }.inject(:merge)).number_of_completed_actions
    end

    context 'with 0 completed actions' do
      let(:actions) { [:created_at, :updated_at] }

      it { is_expected.to eq(0) }
    end

    context 'with 1 completed action' do
      let(:actions) { [:created_at, :subscription_created_at] }

      it { is_expected.to eq(1) }
    end

    context 'with 2 completed actions' do
      let(:actions) { [:subscription_created_at, :git_write_at] }

      it { is_expected.to eq(2) }
    end
  end
end
