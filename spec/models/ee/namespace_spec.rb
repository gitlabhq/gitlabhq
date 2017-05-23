require 'spec_helper'

describe Namespace, models: true do
  let!(:namespace) { create(:namespace) }

  it { is_expected.to have_one(:namespace_statistics).dependent(:destroy) }

  it { is_expected.to delegate_method(:shared_runners_minutes).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:shared_runners_seconds).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:shared_runners_seconds_last_reset).to(:namespace_statistics) }
  it { is_expected.to validate_inclusion_of(:plan).in_array(Namespace::EE_PLANS.keys).allow_nil }

  describe '#feature_available?' do
    let(:group) { create(:group, plan: plan_license) }

    subject { group.feature_available?(feature) }

    context 'when feature available' do
      let(:feature) { :deploy_board }
      let(:plan_license) { Namespace::GOLD_PLAN }

      context 'when feature available for current group' do
        it 'returns false' do
          is_expected.to eq(true)
        end
      end

      context 'when license is applied to parent group' do
        let(:child_group) { create :group, parent: group }

        it 'child group has feature available' do
          expect(child_group.feature_available?(feature)).to eq(true)
        end
      end
    end

    context 'when feature not available' do
      let(:feature) { :deploy_board }
      let(:plan_license) { Namespace::BRONZE_PLAN }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end
  end

  describe '#shared_runners_enabled?' do
    subject { namespace.shared_runners_enabled? }

    context 'without projects' do
      it { is_expected.to be_falsey }
    end

    context 'with project' do
      context 'and disabled shared runners' do
        let!(:project) do
          create(:empty_project,
            namespace: namespace,
            shared_runners_enabled: false)
        end

        it { is_expected.to be_falsey }
      end

      context 'and enabled shared runners' do
        let!(:project) do
          create(:empty_project,
            namespace: namespace,
            shared_runners_enabled: true)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#actual_shared_runners_minutes_limit' do
    subject { namespace.actual_shared_runners_minutes_limit }

    context 'when no limit defined' do
      it { is_expected.to be_zero }
    end

    context 'when application settings limit is set' do
      before do
        stub_application_setting(shared_runners_minutes: 1000)
      end

      it 'returns global limit' do
        is_expected.to eq(1000)
      end

      context 'when namespace limit is set' do
        before do
          namespace.shared_runners_minutes_limit = 500
        end

        it 'returns namespace limit' do
          is_expected.to eq(500)
        end
      end
    end
  end

  describe '#shared_runners_minutes_limit_enabled?' do
    subject { namespace.shared_runners_minutes_limit_enabled? }

    context 'with project' do
      let!(:project) do
        create(:empty_project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      context 'when no limit defined' do
        it { is_expected.to be_falsey }
      end

      context 'when limit is defined' do
        before do
          namespace.shared_runners_minutes_limit = 500
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'without project' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#shared_runners_minutes_used?' do
    subject { namespace.shared_runners_minutes_used? }

    context 'with project' do
      let!(:project) do
        create(:empty_project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      context 'when limit is defined' do
        context 'when limit is used' do
          let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }

          it { is_expected.to be_truthy }
        end

        context 'when limit not yet used' do
          let(:namespace) { create(:namespace, :with_not_used_build_minutes_limit) }

          it { is_expected.to be_falsey }
        end

        context 'when minutes are not yet set' do
          it { is_expected.to be_falsey }
        end
      end

      context 'without limit' do
        let(:namespace) { create(:namespace, :with_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end
    end

    context 'without project' do
      it { is_expected.to be_falsey }
    end
  end
end
