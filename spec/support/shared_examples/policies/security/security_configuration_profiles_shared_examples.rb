# frozen_string_literal: true

# https://docs.gitlab.com/user/application_security/configuration/security_configuration_profiles/

RSpec.shared_examples 'sets Security Configuration Profiles permissions for the project' do
  using RSpec::Parameterized::TableSyntax

  describe 'read_security_scan_profiles' do
    let(:policy) { :read_security_scan_profiles }

    context 'when security_scan_profiles is available' do
      before do
        stub_licensed_features(security_scan_profiles: true)
        enable_admin_mode!(current_user) if role == :admin
      end

      where(:role, :allowed) do
        :guest            | false
        :planner          | false
        :reporter         | false
        :security_manager | true
        :developer        | true
        :maintainer       | true
        :owner            | true
        :admin            | true
        :auditor          | false
      end

      with_them do
        let(:current_user) { public_send(role) }

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end

    context 'when security_scan_profiles is not available' do
      where(:role) do
        Gitlab::Access.sym_options_with_admin.keys
      end

      with_them do
        let(:current_user) { public_send(role) }

        before do
          enable_admin_mode!(current_user) if role == :admin
        end

        it { expect_disallowed(policy) }
      end
    end
  end

  describe 'apply_security_scan_profiles' do
    let(:policy) { :apply_security_scan_profiles }

    where(:role, :licensed, :allowed) do
      :maintainer       | true  | true
      :owner            | true  | true
      :admin            | true  | true
      :developer        | true  | false
      :security_manager | true  | true
      :reporter         | true  | false
      :planner          | true  | false
      :guest            | true  | false
      :auditor          | true  | false
      :maintainer       | false | false
      :owner            | false | false
      :admin            | false | false
      :developer        | false | false
      :security_manager | false | false
      :reporter         | false | false
      :planner          | false | false
      :guest            | false | false
      :auditor          | false | false
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        stub_licensed_features(security_scan_profiles: licensed)
        enable_admin_mode!(current_user) if role == :admin
      end

      it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
    end

    context 'with a custom role' do
      include_context 'with custom role in project'

      let(:member_role_abilities) { { apply_security_scan_profiles: true } }
      let(:allowed_abilities) { [:apply_security_scan_profiles] }
      let(:licensed_features) { { security_scan_profiles: true } }

      it_behaves_like 'custom roles abilities'

      it_behaves_like 'does not call custom role query', [:security_manager, :maintainer, :owner]
    end
  end
end

RSpec.shared_examples 'sets Security Configuration Profiles permissions for the group' do
  using RSpec::Parameterized::TableSyntax

  describe 'read_security_scan_profiles' do
    let(:permission) { :read_security_scan_profiles }

    where(:role, :licensed, :allowed) do
      :owner            | true   | true
      :maintainer       | true   | true
      :developer        | true   | true
      :security_manager | true   | true
      :reporter         | true   | false
      :planner          | true   | false
      :guest            | true   | false
      :owner            | false  | false
      :maintainer       | false  | false
      :developer        | false  | false
      :security_manager | false  | false
      :reporter         | false  | false
      :planner          | false  | false
      :guest            | false  | false
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        stub_licensed_features(security_scan_profiles: licensed)
      end

      it { is_expected.to(allowed ? be_allowed(permission) : be_disallowed(permission)) }
    end

    describe 'with custom role' do
      include_context 'with custom role in group'

      let(:licensed_features) { { security_scan_profiles: true } }
      let(:member_role_abilities) { { read_security_scan_profiles: true } }
      let(:allowed_abilities) { [permission] }

      it_behaves_like 'custom roles abilities'

      it_behaves_like 'does not call custom role query', [:developer, :maintainer, :owner, :security_manager]
    end
  end

  describe 'apply_security_scan_profiles' do
    let(:policy) { :apply_security_scan_profiles }

    where(:role, :licensed, :allowed) do
      :maintainer       | true  | true
      :owner            | true  | true
      :admin            | true  | true
      :developer        | true  | false
      :security_manager | true  | true
      :reporter         | true  | false
      :planner          | true  | false
      :guest            | true  | false
      :auditor          | true  | false
      :maintainer       | false | false
      :owner            | false | false
      :admin            | false | false
      :developer        | false | false
      :security_manager | false | false
      :reporter         | false | false
      :planner          | false | false
      :guest            | false | false
      :auditor          | false | false
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        stub_licensed_features(security_scan_profiles: licensed)
        enable_admin_mode!(current_user) if role == :admin
      end

      it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
    end

    describe 'with custom role' do
      include_context 'with custom role in group'

      let(:licensed_features) { { security_scan_profiles: true } }
      let(:member_role_abilities) { { apply_security_scan_profiles: true } }
      let(:allowed_abilities) { [:apply_security_scan_profiles] }

      it_behaves_like 'custom roles abilities'

      it_behaves_like 'does not call custom role query', [:security_manager, :developer, :maintainer, :owner]
    end
  end
end
