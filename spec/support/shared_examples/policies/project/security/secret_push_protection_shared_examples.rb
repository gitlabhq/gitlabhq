# frozen_string_literal: true

# https://docs.gitlab.com/user/application_security/secret_detection/secret_push_protection/
RSpec.shared_examples 'sets Secret Push Protection permissions for the project' do
  using RSpec::Parameterized::TableSyntax

  describe 'enable_secret_push_protection' do
    where(:current_user, :licensed, :match_expected_result) do
      ref(:owner)            | true  | be_allowed(:enable_secret_push_protection)
      ref(:maintainer)       | true  | be_allowed(:enable_secret_push_protection)
      ref(:developer)        | true  | be_disallowed(:enable_secret_push_protection)
      ref(:security_manager) | true  | be_allowed(:enable_secret_push_protection)
      ref(:owner)            | false | be_disallowed(:enable_secret_push_protection)
      ref(:maintainer)       | false | be_disallowed(:enable_secret_push_protection)
      ref(:developer)        | false | be_disallowed(:enable_secret_push_protection)
      ref(:security_manager) | false | be_disallowed(:enable_secret_push_protection)
    end

    with_them do
      before do
        stub_licensed_features(secret_push_protection: licensed)
      end

      it { is_expected.to match_expected_result }
    end

    describe 'when the project does not have the correct license' do
      let(:current_user) { owner }

      it { expect_disallowed(:enable_secret_push_protection) }
    end

    context 'for public .com projects without Ultimate license' do
      let_it_be(:project) { public_project }

      before do
        stub_licensed_features(secret_push_protection: false)
        stub_saas_features(auto_enable_secret_push_protection_public_projects: true)
        stub_feature_flags(auto_spp_public_com_projects: true)
      end

      where(:current_user, :match_expected_result) do
        ref(:owner)            | be_allowed(:enable_secret_push_protection)
        ref(:maintainer)       | be_allowed(:enable_secret_push_protection)
        ref(:developer)        | be_disallowed(:enable_secret_push_protection)
        ref(:security_manager) | be_allowed(:enable_secret_push_protection)
        ref(:reporter)         | be_disallowed(:enable_secret_push_protection)
        ref(:guest)            | be_disallowed(:enable_secret_push_protection)
      end

      with_them do
        it { is_expected.to match_expected_result }
      end

      context 'when project is private' do
        let_it_be(:project) { create(:project, :private) }
        let(:current_user) { owner }

        it { expect_disallowed(:enable_secret_push_protection) }
      end

      context 'when feature flag is disabled' do
        let(:current_user) { owner }

        before do
          stub_feature_flags(auto_spp_public_com_projects: false)
        end

        it { expect_disallowed(:enable_secret_push_protection) }
      end

      context 'when not on .com' do
        let(:current_user) { owner }

        before do
          stub_saas_features(auto_enable_secret_push_protection_public_projects: false)
        end

        it { expect_disallowed(:enable_secret_push_protection) }
      end
    end
  end

  describe 'read_secret_push_protection_info' do
    where(:current_user, :match_expected_result) do
      ref(:owner)            | be_allowed(:read_secret_push_protection_info)
      ref(:maintainer)       | be_allowed(:read_secret_push_protection_info)
      ref(:developer)        | be_allowed(:read_secret_push_protection_info)
      ref(:security_manager) | be_allowed(:read_secret_push_protection_info)
      ref(:planner)          | be_disallowed(:read_secret_push_protection_info)
      ref(:guest)            | be_disallowed(:read_secret_push_protection_info)
      ref(:non_member)       | be_disallowed(:read_secret_push_protection_info)
    end

    with_them do
      before do
        stub_licensed_features(secret_push_protection: true)
      end

      it { is_expected.to match_expected_result }
    end
  end

  # https://docs.gitlab.com/user/application_security/secret_detection/exclusions/
  describe 'Secret detection exclusions' do
    describe 'manage_project_security_exclusions' do
      let(:policy) { :manage_project_security_exclusions }

      where(:role, :allowed) do
        :guest            | false
        :planner          | false
        :reporter         | false
        :security_manager | true
        :developer        | false
        :maintainer       | true
        :auditor          | false
        :owner            | true
        :admin            | true
      end

      with_them do
        let(:current_user) { public_send(role) }

        before do
          enable_admin_mode!(current_user) if role == :admin
        end

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end

    describe 'read_project_security_exclusions' do
      let(:policy) { :read_project_security_exclusions }

      where(:role, :allowed) do
        :guest            | false
        :planner          | false
        :reporter         | false
        :security_manager | true
        :developer        | true
        :maintainer       | true
        :auditor          | true
        :owner            | true
        :admin            | true
      end

      with_them do
        let(:current_user) { public_send(role) }

        before do
          enable_admin_mode!(current_user) if role == :admin
        end

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end
  end
end
