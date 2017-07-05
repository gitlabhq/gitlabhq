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

  describe '#push_rule' do
    let(:project) { create(:project, push_rule: create(:push_rule)) }

    subject(:push_rule) { project.push_rule(true) }

    it { is_expected.not_to be_nil }

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it { is_expected.to be_nil }
    end
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
        stub_licensed_features(feature => allowed_on_global_license)
        allow(namespace).to receive(:plan) { plan_license }
      end

      License::FEATURE_CODES.each do |feature_sym, feature_code|
        context feature_sym.to_s do
          let(:feature) { feature_sym }
          let(:feature_code) { feature_code }

          context "checking #{feature_sym} availability both on Global and Namespace license" do
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

            unless License.plan_includes_feature?(License::STARTER_PLAN, feature_sym)
              context 'not allowed by Plan License' do
                let(:allowed_on_global_license) { true }
                let(:plan_license) { Namespace::BRONZE_PLAN }

                it 'returns false' do
                  is_expected.to eq(false)
                end
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
    end

    it 'only loads licensed availability once' do
      expect(project).to receive(:load_licensed_feature_available)
                             .once.and_call_original

      2.times { project.feature_available?(:service_desk) }
    end

    context 'when feature symbol is not included on Namespace features code' do
      let(:feature) { :issues }

      it 'checks availability of licensed feature' do
        expect(project.project_feature).to receive(:feature_available?).with(feature, user)

        subject
      end
    end
  end

  describe '#mirror_waiting_duration' do
    it 'returns in seconds the time spent in the queue' do
      project = create(:empty_project, :mirror, :import_scheduled)
      mirror_data = project.mirror_data

      mirror_data.update_attributes(last_update_started_at: mirror_data.last_update_scheduled_at + 5.minutes)

      expect(project.mirror_waiting_duration).to eq(300)
    end
  end

  describe '#mirror_update_duration' do
    it 'returns in seconds the time spent updating' do
      project = create(:empty_project, :mirror, :import_started)

      project.update_attributes(mirror_last_update_at: project.mirror_data.last_update_started_at + 5.minutes)

      expect(project.mirror_update_duration).to eq(300)
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

  describe '#service_desk_enabled?' do
    let!(:license) { create(:license, data: build(:gitlab_license, restrictions: { plan: License::PREMIUM_PLAN }).export) }
    let(:namespace) { create(:namespace) }

    subject(:project) { build(:empty_project, :private, namespace: namespace, service_desk_enabled: true) }

    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
      allow(::Gitlab::IncomingEmail).to receive(:enabled?).and_return(true)
      allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(true)
    end

    it 'is enabled' do
      expect(project.service_desk_enabled?).to be_truthy
      expect(project.service_desk_enabled).to be_truthy
    end

    context 'namespace plans active' do
      before do
        stub_application_setting(check_namespace_plan: true)
      end

      it 'is disabled' do
        expect(project.service_desk_enabled?).to be_falsy
        expect(project.service_desk_enabled).to be_falsy
      end

      context 'Service Desk available in namespace plan' do
        let(:namespace) { create(:namespace, plan: Namespace::SILVER_PLAN) }

        it 'is enabled' do
          expect(project.service_desk_enabled?).to be_truthy
          expect(project.service_desk_enabled).to be_truthy
        end
      end
    end
  end

  describe '#service_desk_address' do
    let(:project) { create(:empty_project, service_desk_enabled: true) }

    before do
      allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(true)
      allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)
      allow(Gitlab.config.incoming_email).to receive(:address).and_return("test+%{key}@mail.com")
    end

    it 'uses project full path as service desk address key' do
      expect(project.service_desk_address).to eq("test+#{project.full_path}@mail.com")
    end
  end

  describe '#approvals_before_merge' do
    [
      { license: true,  database: 5,  expected: 5 },
      { license: true,  database: 0,  expected: 0 },
      { license: false, database: 5,  expected: 0 },
      { license: false, database: 0,  expected: 0 }
    ].each do |spec|
      context spec.inspect do
        let(:spec) { spec }
        let(:project) { build(:project, approvals_before_merge: spec[:database]) }

        subject { project.approvals_before_merge }

        before do
          stub_licensed_features(merge_request_approvers: spec[:license])
        end

        it { is_expected.to eq(spec[:expected]) }
      end
    end
  end

  describe "#reset_approvals_on_push?" do
    [
      { license: true,  database: true,  expected: true },
      { license: true,  database: false, expected: false },
      { license: false, database: true,  expected: false },
      { license: false, database: false, expected: false }
    ].each do |spec|
      context spec.inspect do
        let(:spec) { spec }
        let(:project) { build(:project, reset_approvals_on_push: spec[:database]) }

        subject { project.reset_approvals_on_push? }

        before do
          stub_licensed_features(merge_request_approvers: spec[:license])
        end

        it { is_expected.to eq(spec[:expected]) }
      end
    end
  end

  describe '#approvals_before_merge' do
    [
      { license: true,  database: 5,  expected: 5 },
      { license: true,  database: 0,  expected: 0 },
      { license: false, database: 5,  expected: 0 },
      { license: false, database: 0,  expected: 0 }
    ].each do |spec|
      context spec.inspect do
        let(:spec) { spec }
        let(:project) { build(:project, approvals_before_merge: spec[:database]) }

        subject { project.approvals_before_merge }

        before do
          stub_licensed_features(merge_request_approvers: spec[:license])
        end

        it { is_expected.to eq(spec[:expected]) }
      end
    end
  end

  describe '#merge_method' do
    [
      { ff: true,  rebase: true,  ff_licensed: true,  rebase_licensed: true,  method: :ff },
      { ff: true,  rebase: true,  ff_licensed: true,  rebase_licensed: false, method: :ff },
      { ff: true,  rebase: true,  ff_licensed: false, rebase_licensed: true,  method: :rebase_merge },
      { ff: true,  rebase: true,  ff_licensed: false, rebase_licensed: false, method: :merge },
      { ff: true,  rebase: false, ff_licensed: true,  rebase_licensed: true,  method: :ff },
      { ff: true,  rebase: false, ff_licensed: true,  rebase_licensed: false, method: :ff },
      { ff: true,  rebase: false, ff_licensed: false, rebase_licensed: true,  method: :merge },
      { ff: true,  rebase: false, ff_licensed: false, rebase_licensed: false, method: :merge },
      { ff: false, rebase: true,  ff_licensed: true,  rebase_licensed: true,  method: :rebase_merge },
      { ff: false, rebase: true,  ff_licensed: true,  rebase_licensed: false, method: :merge },
      { ff: false, rebase: true,  ff_licensed: false, rebase_licensed: true,  method: :rebase_merge },
      { ff: false, rebase: true,  ff_licensed: false, rebase_licensed: false, method: :merge },
      { ff: false, rebase: false, ff_licensed: true,  rebase_licensed: true,  method: :merge },
      { ff: false, rebase: false, ff_licensed: true,  rebase_licensed: false, method: :merge },
      { ff: false, rebase: false, ff_licensed: false, rebase_licensed: true,  method: :merge },
      { ff: false, rebase: false, ff_licensed: false, rebase_licensed: false, method: :merge }
    ].each do |spec|
      context spec.inspect do
        let(:project) { build(:empty_project, merge_requests_rebase_enabled: spec[:rebase], merge_requests_ff_only_enabled: spec[:ff]) }
        let(:spec) { spec }

        subject { project.merge_method }

        before do
          stub_licensed_features(merge_request_rebase: spec[:rebase_licensed], fast_forward_merge: spec[:ff_licensed])
        end

        it { is_expected.to eq(spec[:method]) }
      end
    end
  end
end
