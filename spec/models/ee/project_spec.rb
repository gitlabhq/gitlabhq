require 'spec_helper'

describe Project, models: true do
  describe 'associations' do
    it { is_expected.to delegate_method(:shared_runners_minutes).to(:statistics) }
    it { is_expected.to delegate_method(:shared_runners_seconds).to(:statistics) }
    it { is_expected.to delegate_method(:shared_runners_seconds_last_reset).to(:statistics) }

    it { is_expected.to delegate_method(:actual_shared_runners_minutes_limit).to(:namespace) }
    it { is_expected.to delegate_method(:shared_runners_minutes_limit_enabled?).to(:namespace) }
    it { is_expected.to delegate_method(:shared_runners_minutes_used?).to(:namespace) }
  end

  describe '#feature_available?' do
    let(:namespace) { build_stubbed(:namespace) }
    let(:project) { build_stubbed(:project, namespace: namespace) }
    let(:user) { build_stubbed(:user) }

    subject { project.feature_available?(feature, user) }

    context 'when feature symbol is included on Namespace features code' do
      before do
        stub_application_setting('check_namespace_plan?' => check_namespace_plan)
        allow(Gitlab).to receive(:com?) { true }
        expect_any_instance_of(License).to receive(:feature_available?).with(feature) { allowed_on_global_license }
        allow(namespace).to receive(:plan) { plan_license }
      end

      License::FEATURE_CODES.each do |feature_sym, feature_code|
        let(:feature) { feature_sym }
        let(:feature_code) { feature_code }

        context "checking #{feature} availabily both on Global and Namespace license" do
          let(:check_namespace_plan) { true }

          context 'allowed by Plan License AND Global License' do
            let(:allowed_on_global_license) { true }
            let(:plan_license) { Namespace::GOLD_PLAN }

            it 'returns true' do
              is_expected.to eq(true)
            end
          end

          context 'not allowed by Plan License but project and namespace are public' do
            let(:allowed_on_global_license) { true }
            let(:plan_license) { Namespace::BRONZE_PLAN }

            it 'returns true' do
              allow(namespace).to receive(:public?) { true }
              allow(project).to receive(:public?) { true }

              is_expected.to eq(true)
            end
          end

          context 'not allowed by Plan License' do
            let(:allowed_on_global_license) { true }
            let(:plan_license) { Namespace::BRONZE_PLAN }

            it 'returns false' do
              is_expected.to eq(false)
            end
          end

          context 'not allowed by Global License' do
            let(:allowed_on_global_license) { false }
            let(:plan_license) { Namespace::GOLD_PLAN }

            it 'returns false' do
              is_expected.to eq(false)
            end
          end
        end

        context "when checking #{feature_code} only for Global license" do
          let(:check_namespace_plan) { false }

          context 'allowed by Global License' do
            let(:allowed_on_global_license) { true }

            it 'returns true' do
              is_expected.to eq(true)
            end
          end

          context 'not allowed by Global License' do
            let(:allowed_on_global_license) { false }

            it 'returns false' do
              is_expected.to eq(false)
            end
          end
        end
      end
    end

    context 'when feature symbol is not included on Namespace features code' do
      let(:feature) { :issues }

      it 'checks availability of licensed feature' do
        expect(project.project_feature).to receive(:feature_available?).with(feature, user)

        subject
      end
    end
  end

  describe '#any_runners_limit' do
    let(:project) { create(:empty_project, shared_runners_enabled: shared_runners_enabled) }
    let(:specific_runner) { create(:ci_runner) }
    let(:shared_runner) { create(:ci_runner, :shared) }

    context 'for shared runners enabled' do
      let(:shared_runners_enabled) { true }

      before do
        shared_runner
      end

      it 'has a shared runner' do
        expect(project.any_runners?).to be_truthy
      end

      it 'checks the presence of shared runner' do
        expect(project.any_runners? { |runner| runner == shared_runner }).to be_truthy
      end

      context 'with used pipeline minutes' do
        let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
        let(:project) do
          create(:empty_project,
            namespace: namespace,
            shared_runners_enabled: shared_runners_enabled)
        end

        it 'does not have a shared runner' do
          expect(project.any_runners?).to be_falsey
        end
      end
    end
  end

  describe '#shared_runners_available?' do
    subject { project.shared_runners_available? }

    context 'with used pipeline minutes' do
      let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
      let(:project) do
        create(:empty_project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      before do
        expect(namespace).to receive(:shared_runners_minutes_used?).and_call_original
      end

      it 'shared runners are not available' do
        expect(project.shared_runners_available?).to be_falsey
      end
    end
  end

  describe '#shared_runners_minutes_limit_enabled?' do
    let(:project) { create(:empty_project) }

    subject { project.shared_runners_minutes_limit_enabled? }

    before do
      allow(project.namespace).to receive(:shared_runners_minutes_limit_enabled?)
        .and_return(true)
    end

    context 'with shared runners enabled' do
      before do
        project.shared_runners_enabled = true
      end

      context 'for public project' do
        before do
          project.visibility_level = Project::PUBLIC
        end

        it { is_expected.to be_falsey }
      end

      context 'for internal project' do
        before do
          project.visibility_level = Project::INTERNAL
        end

        it { is_expected.to be_truthy }
      end

      context 'for private project' do
        before do
          project.visibility_level = Project::INTERNAL
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'without shared runners' do
      before do
        project.shared_runners_enabled = false
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#service_desk_address' do
    let(:project) { create(:empty_project, service_desk_enabled: true) }

    before do
      allow_any_instance_of(License).to receive(:feature_available?).and_call_original
      allow_any_instance_of(License).to receive(:feature_available?).with(:service_desk) { true }
      allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)
      allow(Gitlab.config.incoming_email).to receive(:address).and_return("test+%{key}@mail.com")
    end

    it 'uses project full path as service desk address key' do
      expect(project.service_desk_address).to eq("test+#{project.full_path}@mail.com")
    end
  end
end
