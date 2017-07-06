require 'spec_helper'

describe Namespace, models: true do
  let!(:namespace) { create(:namespace) }

  it { is_expected.to have_one(:namespace_statistics) }

  it { is_expected.to delegate_method(:shared_runners_minutes).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:shared_runners_seconds).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:shared_runners_seconds_last_reset).to(:namespace_statistics) }
  it { is_expected.to validate_inclusion_of(:plan).in_array(Namespace::EE_PLANS.keys).allow_blank }

  context 'scopes' do
    describe '.with_plan' do
      let!(:namespace) { create :namespace, plan: namespace_plan }

      context 'plan is set' do
        let(:namespace_plan) { EE::Namespace::BRONZE_PLAN }

        it 'returns namespaces with plan' do
          expect(described_class.with_plan).to eq([namespace])
        end
      end

      context 'plan is not set' do
        context 'plan is empty string' do
          let(:namespace_plan) { '' }

          it 'returns no namespace' do
            expect(described_class.with_plan).to be_empty
          end
        end

        context 'plan is nil' do
          let(:namespace_plan) { nil }

          it 'returns no namespace' do
            expect(described_class.with_plan).to be_empty
          end
        end
      end
    end
  end

  describe '#move_dir' do
    context 'when running on a primary node' do
      let!(:geo_node) { create(:geo_node, :primary, :current) }
      let(:gitlab_shell) { Gitlab::Shell.new }

      it 'logs the Geo::RepositoryRenamedEvent for each project inside namespace' do
        parent = create(:namespace)
        child = create(:group, name: 'child', path: 'child', parent: parent)
        project_1 = create(:project_empty_repo, namespace: parent)
        create(:project_empty_repo, namespace: child)
        full_path_was = "#{parent.full_path}_old"
        new_path = parent.full_path

        allow(parent).to receive(:gitlab_shell).and_return(gitlab_shell)
        allow(parent).to receive(:path_changed?).and_return(true)
        allow(parent).to receive(:full_path_was).and_return(full_path_was)
        allow(parent).to receive(:full_path).and_return(new_path)

        allow(gitlab_shell).to receive(:mv_namespace)
          .ordered
          .with(project_1.repository_storage_path, full_path_was, new_path)
          .and_return(true)

        expect { parent.move_dir }.to change(Geo::RepositoryRenamedEvent, :count).by(2)
      end
    end
  end

  describe '#feature_available?' do
    let(:plan_license) { Namespace::BRONZE_PLAN }
    let(:group) { create(:group, plan: plan_license) }
    let(:feature) { :service_desk }

    subject { group.feature_available?(feature) }

    before do
      stub_licensed_features(feature => true)
    end

    it 'uses the global setting when running on premise' do
      stub_application_setting_on_object(group, should_check_namespace_plan: false)

      is_expected.to be_truthy
    end

    it 'only checks the plan once' do
      expect(group).to receive(:load_feature_available).once.and_call_original

      2.times { group.feature_available?(:service_desk) }
    end

    context 'when checking namespace plan' do
      before do
        stub_application_setting_on_object(group, should_check_namespace_plan: true)
      end

      it 'combines the global setting with the group setting when not running on premise' do
        is_expected.to be_falsy
      end

      context 'when feature available on the plan' do
        let(:plan_license) { Namespace::GOLD_PLAN }

        context 'when feature available for current group' do
          it 'returns true' do
            is_expected.to be_truthy
          end
        end

        if Group.supports_nested_groups?
          context 'when license is applied to parent group' do
            let(:child_group) { create :group, parent: group }

            it 'child group has feature available' do
              expect(child_group.feature_available?(feature)).to be_truthy
            end
          end
        end
      end

      context 'when feature not available in the plan' do
        let(:feature) { :deploy_board }
        let(:plan_license) { Namespace::BRONZE_PLAN }

        it 'returns false' do
          is_expected.to be_falsy
        end
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
