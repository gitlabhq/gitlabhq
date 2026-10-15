# frozen_string_literal: true

# https://docs.gitlab.com/user/application_security/configuration/security_configuration_profiles/

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
      :auditor          | true   | true
      :owner            | false  | false
      :maintainer       | false  | false
      :developer        | false  | false
      :security_manager | false  | false
      :reporter         | false  | false
      :planner          | false  | false
      :guest            | false  | false
      :auditor          | false  | false
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        stub_licensed_features(security_scan_profiles: licensed)
      end

      it { allowed ? expect_allowed(permission) : expect_disallowed(permission) }
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

      it { allowed ? expect_allowed(policy) : expect_disallowed(policy) }
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
