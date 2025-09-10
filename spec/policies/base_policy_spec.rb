# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BasePolicy, feature_category: :shared do
  include ExternalAuthorizationServiceHelpers
  include AdminModeHelper

  describe '.class_for' do
    it 'detects policy class based on the subject ancestors' do
      expect(DeclarativePolicy.class_for(GenericCommitStatus.new)).to eq(CommitStatusPolicy)
    end

    it 'detects policy class for a presented subject' do
      presentee = Ci::BuildPresenter.new(Ci::Build.new)

      expect(DeclarativePolicy.class_for(presentee)).to eq(Ci::BuildPolicy)
    end

    it 'uses GlobalPolicy when :global is given' do
      expect(DeclarativePolicy.class_for(:global)).to eq(GlobalPolicy)
    end
  end

  shared_examples 'admin only access' do |ability|
    def policy
      # method, because we want a fresh cache each time.
      described_class.new(current_user, nil)
    end

    let(:current_user) { build_stubbed(:user) }

    subject { policy }

    it { is_expected.not_to be_allowed(ability) }

    context 'with an admin' do
      let(:current_user) { build_stubbed(:admin) }

      it 'allowed when in admin mode' do
        enable_admin_mode!(current_user)

        is_expected.to be_allowed(ability)
      end

      context 'when user from job token' do
        before do
          allow(current_user).to receive(:from_ci_job_token?).and_return(true)
          enable_admin_mode!(current_user)
        end

        it 'prevents when settings in admin mode' do
          allow(Gitlab::CurrentSettings).to receive(:admin_mode).and_return(false)

          is_expected.to be_disallowed(ability)
        end

        it 'prevents when user is admin' do
          is_expected.to be_disallowed(ability)
        end
      end

      it 'prevented when not in admin mode' do
        is_expected.not_to be_allowed(ability)
      end
    end

    context 'with the admin bot user' do
      let(:current_user) { create(:user, :admin_bot) }

      it { is_expected.to be_allowed(ability) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(ability) }
    end

    describe 'bypassing the session for sessionless login', :request_store do
      let(:current_user) { build_stubbed(:admin) }

      it 'changes from prevented to allowed' do
        expect { Gitlab::Auth::CurrentUserMode.bypass_session!(current_user.id) }
          .to change { policy.allowed?(ability) }.from(false).to(true)
      end
    end

    context 'with a limited admin user', :enable_admin_mode do
      let(:current_user) { build_stubbed(:user) }

      before do
        allow(current_user).to receive(:can_access_admin_area?).and_return(true)
      end

      it { is_expected.not_to be_allowed(ability) }
    end
  end

  describe 'read_dedicated_hosted_runner_usage' do
    let(:current_user) { build_stubbed(:user) }

    subject { described_class.new(current_user, nil) }

    context 'for a regular user' do
      it { is_expected.not_to be_allowed(:read_dedicated_hosted_runner_usage) }
    end

    context 'with an admin' do
      let(:current_user) { build_stubbed(:admin) }

      before do
        enable_admin_mode!(current_user)
      end

      context 'on a non-dedicated instance' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:gitlab_dedicated_instance?).and_return(false)
        end

        it { is_expected.not_to be_allowed(:read_dedicated_hosted_runner_usage) }
      end

      context 'on a dedicated instance' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:gitlab_dedicated_instance?).and_return(true)
        end

        it { is_expected.to be_allowed(:read_dedicated_hosted_runner_usage) }
      end
    end

    context 'with an admin not in admin mode' do
      let(:current_user) { build_stubbed(:admin) }

      before do
        allow(Gitlab::CurrentSettings).to receive(:gitlab_dedicated_instance?).and_return(true)
      end

      it { is_expected.not_to be_allowed(:read_dedicated_hosted_runner_usage) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      before do
        allow(Gitlab::CurrentSettings).to receive(:gitlab_dedicated_instance?).and_return(true)
      end

      it { is_expected.not_to be_allowed(:read_dedicated_hosted_runner_usage) }
    end
  end

  describe 'read cross project' do
    let(:current_user) { build_stubbed(:user) }
    let(:user) { build_stubbed(:user) }

    subject { described_class.new(current_user, [user]) }

    it { is_expected.to be_allowed(:read_cross_project) }

    context 'for anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_allowed(:read_cross_project) }
    end

    context 'when an external authorization service is enabled' do
      before do
        enable_external_authorization_service_check
      end

      it_behaves_like 'admin only access', :read_cross_project
    end
  end

  describe 'full private access: read_all_resources' do
    it_behaves_like 'admin only access', :read_all_resources
  end

  describe 'full private access: admin_all_resources' do
    it_behaves_like 'admin only access', :admin_all_resources
  end

  describe 'change_repository_storage' do
    it_behaves_like 'admin only access', :change_repository_storage
  end

  describe 'placeholder_user' do
    let(:current_user) { build_stubbed(:user, user_type: :placeholder) }

    subject { described_class.new(current_user, nil) }

    it { expect_disallowed(:access_git) }
    it { expect_disallowed(:log_in) }
    it { expect_disallowed(:access_api) }
    it { expect_disallowed(:receive_notifications) }
    it { expect_disallowed(:use_slash_commands) }
  end

  describe 'import_user' do
    let(:current_user) { build_stubbed(:user, user_type: :import_user) }

    subject { described_class.new(current_user, nil) }

    it { expect_disallowed(:access_git) }
    it { expect_disallowed(:log_in) }
    it { expect_disallowed(:access_api) }
    it { expect_disallowed(:receive_notifications) }
    it { expect_disallowed(:use_slash_commands) }
  end

  describe 'in_current_organization' do
    let_it_be(:current_organization) { create(:organization) }
    let_it_be(:other_organization) { create(:organization) }
    let_it_be(:policy_subject) { create(:group, :public, organization: other_organization) }

    let(:current_user) { nil }

    subject(:group_policy) do
      GroupPolicy.new(current_user, policy_subject)
    end

    context 'when feature flag :current_organization_policy is disabled' do
      before do
        stub_feature_flags(current_organization_policy: false)
      end

      it 'allows access to the subject' do
        expect(group_policy).to be_allowed(:read_group)
      end
    end

    context 'when user is an admin' do
      let(:current_user) { build_stubbed(:admin) }

      it 'allows access to the subject' do
        expect(group_policy).to be_allowed(:read_group)
      end
    end

    context 'when current organization is set' do
      before do
        Current.organization = current_organization
      end

      context 'when subject is not in current organization' do
        context 'and it has an organization_id' do
          let_it_be(:policy_subject) { create(:group, :public, organization: other_organization) }

          it 'disallows all access to the subject' do
            expect(group_policy).to be_disallowed(:read_group)
          end

          context 'and organization_id is nil' do
            before do
              allow(policy_subject).to receive(:organization_id).and_return(nil)
            end

            it 'allows access to the subject' do
              expect(group_policy).to be_allowed(:read_group)
            end
          end

          context 'when subject is an Organization instance' do
            let_it_be(:current_user) { create(:user, organization: other_organization) }

            subject(:organization_policy) do
              Organizations::OrganizationPolicy.new(
                current_user, other_organization
              ).allowed?(:read_organization)
            end

            it 'allows access to the subject' do
              expect(organization_policy).to be(true)
            end
          end
        end
      end

      context 'when subject is in current organization' do
        context 'and it has an organization_id' do
          let_it_be(:policy_subject) { create(:group, :public, organization: current_organization) }

          it 'allows all access to the subject' do
            expect(group_policy).to be_allowed(:read_group)
          end
        end
      end

      context 'when subject does not have an organization_id attribute' do
        let_it_be(:policy_subject) { create(:group) }

        before do
          allow(policy_subject).to receive(:respond_to?).with('organization_id').and_return(false)
        end

        it 'allows access to the subject' do
          expect(group_policy).to be_allowed(:read_group)
        end
      end

      context 'when subject does not have sharding_key method' do
        let_it_be(:policy_subject) { :global }
        let(:current_user) { build_stubbed(:user) }

        subject(:policy) do
          Ability.allowed?(current_user, :read_cross_project)
        end

        it 'allows access to the subject' do
          expect(policy).to be(true)
        end
      end
    end

    context 'when current organization is nil' do
      before do
        Current.organization = nil
      end

      context 'and subject has an organization_id' do
        let_it_be(:policy_subject) { create(:group, :public, organization: other_organization) }

        it 'allows access to the subject' do
          expect(group_policy).to be_allowed(:read_group)
        end
      end
    end

    context 'when current organization is not assigned' do
      context 'and subject has an organization_id' do
        let_it_be(:policy_subject) { create(:group, :public, organization: other_organization) }

        it 'allows access to the subject' do
          expect(group_policy).to be_allowed(:read_group)
        end
      end
    end
  end
end
