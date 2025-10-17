# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSetting, feature_category: :groups_and_projects, type: :model do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
  let(:namespace_settings) { group.namespace_settings }

  it_behaves_like 'sanitizable', :namespace_settings, %i[default_branch_name]

  # Relationships
  #
  describe "Associations" do
    it { is_expected.to belong_to(:namespace) }
  end

  it { is_expected.to define_enum_for(:jobs_to_be_done).with_values([:basics, :move_repository, :code_storage, :exploring, :ci, :other]).with_suffix }
  it { is_expected.to define_enum_for(:enabled_git_access_protocol).with_values([:all, :ssh, :http]).with_suffix }

  describe 'default values' do
    subject(:setting) { described_class.new }

    it { expect(setting.default_branch_protection_defaults).to eq({}) }
  end

  describe 'scopes' do
    describe '.for_namespaces' do
      let(:setting_1) { create(:namespace_settings, namespace: namespace_1) }
      let(:setting_2) { create(:namespace_settings, namespace: namespace_2) }
      let_it_be(:namespace_1) { create(:namespace) }
      let_it_be(:namespace_2) { create(:namespace) }

      it 'returns namespace setting for the given projects' do
        expect(described_class.for_namespaces(namespace_1)).to contain_exactly(setting_1)
      end
    end

    describe '.with_ancestors_inherited_settings' do
      let_it_be_with_reload(:root_group) { create(:group) }
      let_it_be_with_reload(:child_group) { create(:group, parent: root_group) }
      let_it_be_with_reload(:grandchild_group) { create(:group, parent: child_group) }

      let_it_be_with_reload(:root_settings) { root_group.namespace_settings }
      let_it_be_with_reload(:child_settings) { child_group.namespace_settings }
      let_it_be_with_reload(:grandchild_settings) { grandchild_group.namespace_settings }

      subject(:namespaces_with_ancestors_inherited_settings) { described_class.with_ancestors_inherited_settings }

      context 'when no ancestors are archived' do
        before do
          root_settings.update!(archived: false)
          child_settings.update!(archived: false)
          grandchild_settings.update!(archived: false)
        end

        it 'returns the original archived value for each namespace' do
          results = namespaces_with_ancestors_inherited_settings.index_by(&:namespace_id)

          expect(results[root_group.id].archived).to be false
          expect(results[child_group.id].archived).to be false
          expect(results[grandchild_group.id].archived).to be false
        end
      end

      context 'when root namespace is archived' do
        before do
          root_settings.update!(archived: true)
          child_settings.update!(archived: false)
          grandchild_settings.update!(archived: false)
        end

        it 'marks all descendants as archived' do
          results = namespaces_with_ancestors_inherited_settings.index_by(&:namespace_id)

          expect(results[root_group.id].archived).to be true
          expect(results[child_group.id].archived).to be true
          expect(results[grandchild_group.id].archived).to be true
        end
      end

      context 'when middle namespace is archived' do
        before do
          root_settings.update!(archived: false)
          child_settings.update!(archived: true)
          grandchild_settings.update!(archived: false)
        end

        it 'marks only descendants of archived namespace as archived' do
          results = namespaces_with_ancestors_inherited_settings.index_by(&:namespace_id)

          expect(results[root_group.id].archived).to be false
          expect(results[child_group.id].archived).to be true
          expect(results[grandchild_group.id].archived).to be true
        end
      end

      context 'when leaf namespace is archived' do
        before do
          root_settings.update!(archived: false)
          child_settings.update!(archived: false)
          grandchild_settings.update!(archived: true)
        end

        it 'only affects the leaf namespace itself' do
          results = namespaces_with_ancestors_inherited_settings.index_by(&:namespace_id)

          expect(results[root_group.id].archived).to be false
          expect(results[child_group.id].archived).to be false
          expect(results[grandchild_group.id].archived).to be true
        end
      end

      context 'when multiple ancestors are archived' do
        before do
          root_settings.update!(archived: true)
          child_settings.update!(archived: false)
          grandchild_settings.update!(archived: true)
        end

        it 'inherits archived status from any archived ancestor' do
          results = namespaces_with_ancestors_inherited_settings.index_by(&:namespace_id)

          expect(results[root_group.id].archived).to be true
          expect(results[child_group.id].archived).to be true
          expect(results[grandchild_group.id].archived).to be true
        end
      end

      context 'with separate namespace hierarchies' do
        let_it_be(:other_root) { create(:group) }
        let_it_be(:other_child) { create(:group, parent: other_root) }
        let_it_be(:other_root_settings) { other_root.namespace_settings }
        let_it_be(:other_child_settings) { other_child.namespace_settings }

        before do
          root_settings.update!(archived: true)
        end

        it 'does not affect unrelated namespace hierarchies' do
          results = namespaces_with_ancestors_inherited_settings.index_by(&:namespace_id)

          # First hierarchy - affected by root being archived
          expect(results[root_group.id].archived).to be true
          expect(results[child_group.id].archived).to be true

          # Second hierarchy - unaffected
          expect(results[other_root.id].archived).to be false
          expect(results[other_child.id].archived).to be false
        end
      end
    end
  end

  describe "validations" do
    describe "#default_branch_name_content" do
      shared_examples "doesn't return an error" do
        it "doesn't return an error" do
          expect(namespace_settings.valid?).to be_truthy
          expect(namespace_settings.errors.full_messages).to be_empty
        end
      end

      context "when not set" do
        before do
          namespace_settings.default_branch_name = nil
        end

        it_behaves_like "doesn't return an error"
      end

      context "when set" do
        before do
          namespace_settings.default_branch_name = "example_branch_name"
        end

        it_behaves_like "doesn't return an error"
      end

      context "when an empty string" do
        before do
          namespace_settings.default_branch_name = ""
        end

        it_behaves_like "doesn't return an error"
      end
    end

    context 'default_branch_protections_defaults validations' do
      let(:charset) { [*'a'..'z'] + [*0..9] }
      let(:value) { Array.new(byte_size) { charset.sample }.join }

      context 'when json is more than 1kb' do
        let(:byte_size) { 1.1.kilobytes }

        it { is_expected.not_to allow_value({ name: value }).for(:default_branch_protection_defaults) }
      end

      context 'when json less than 1kb' do
        let(:byte_size) { 0.5.kilobytes }

        it { is_expected.to allow_value({ name: value }).for(:default_branch_protection_defaults) }
      end
    end

    context 'when enterprise bypass confirmation is allowed' do
      subject do
        build(:namespace_settings, allow_enterprise_bypass_placeholder_confirmation: true)
      end

      let(:valid_times) { [1.day.from_now, 30.days.from_now, 1.year.from_now - 1.day] }
      let(:invalid_times) { [nil, 1.day.ago, Time.zone.today, 1.year.from_now] }

      it 'does not allow invalid expiration times' do
        invalid_times.each do |time|
          expect(subject).not_to allow_value(time).for(:enterprise_bypass_expires_at)
        end
      end

      it 'allows valid expiration times' do
        valid_times.each do |time|
          expect(subject).to allow_value(time).for(:enterprise_bypass_expires_at)
        end
      end
    end

    context 'when allow_enterprise_bypass_placeholder_confirmation is false' do
      subject do
        build(:namespace_settings, allow_enterprise_bypass_placeholder_confirmation: false)
      end

      it { expect(subject).to allow_value(nil).for(:enterprise_bypass_expires_at) }
      it { expect(subject).to allow_value('').for(:enterprise_bypass_expires_at) }
      it { expect(subject).to allow_value(1.day.ago).for(:enterprise_bypass_expires_at) }
      it { expect(subject).to allow_value(Time.current).for(:enterprise_bypass_expires_at) }
    end

    context 'for duo_agent_platform_request_count' do
      it { is_expected.to validate_numericality_of(:duo_agent_platform_request_count).is_greater_than_or_equal_to(0) }
    end
  end

  describe '#enterprise_placeholder_bypass_enabled?' do
    subject { namespace_settings.enterprise_placeholder_bypass_enabled? }

    before do
      namespace_settings.assign_attributes(
        allow_enterprise_bypass_placeholder_confirmation: enterprise_bypass_placeholder_confirmation,
        enterprise_bypass_expires_at: expire_at_value
      )
    end

    let(:enterprise_bypass_placeholder_confirmation) { true }
    let(:expire_at_value) { nil }

    context 'when bypass is enabled with future expiry' do
      let(:expire_at_value) { 30.days.from_now }

      it { is_expected.to be true }
    end

    context 'when bypass is enabled but expired' do
      let(:expire_at_value) { 1.day.ago }

      it { is_expected.to be false }
    end

    context 'when bypass is disabled' do
      let(:enterprise_bypass_placeholder_confirmation) { false }
      let(:expire_at_value) { 30.days.from_now }

      it { is_expected.to be false }
    end

    context 'when bypass is enabled without expiry date' do
      let(:expire_at_value) { nil }

      it { is_expected.to be false }
    end
  end

  describe '#prevent_sharing_groups_outside_hierarchy' do
    let(:settings) { create(:namespace_settings, prevent_sharing_groups_outside_hierarchy: true) }
    let!(:group) { create(:group, parent: parent, namespace_settings: settings) }

    subject(:group_sharing_setting) { settings.prevent_sharing_groups_outside_hierarchy }

    context 'when this namespace is a root ancestor' do
      let(:parent) { nil }

      it 'returns the actual stored value' do
        expect(group_sharing_setting).to be_truthy
      end
    end

    context 'when this namespace is a descendant' do
      let(:parent) { create(:group) }

      it 'returns the value stored for the parent settings' do
        expect(group_sharing_setting).to eq(parent.namespace_settings.prevent_sharing_groups_outside_hierarchy)
        expect(group_sharing_setting).to be_falsey
      end
    end
  end

  describe '#show_diff_preview_in_email?' do
    context 'when not a subgroup' do
      context 'when :show_diff_preview_in_email is false' do
        it 'returns false' do
          settings = create(:namespace_settings, show_diff_preview_in_email: false)
          group = create(:group, namespace_settings: settings)

          expect(group.show_diff_preview_in_email?).to be_falsey
        end
      end

      context 'when :show_diff_preview_in_email is true' do
        it 'returns true' do
          settings = create(:namespace_settings, show_diff_preview_in_email: true)
          group = create(:group, namespace_settings: settings)

          expect(group.show_diff_preview_in_email?).to be_truthy
        end
      end

      it 'does not query the db when there is no parent group' do
        group = create(:group)

        expect { group.show_diff_preview_in_email? }.not_to exceed_query_limit(0)
      end
    end

    context 'when a group has parent groups' do
      let(:grandparent) { create(:group, namespace_settings: settings) }
      let(:parent)      { create(:group, parent: grandparent) }
      let!(:group)      { create(:group, parent: parent) }

      context "when a parent group has disabled diff previews" do
        let(:settings) { create(:namespace_settings, show_diff_preview_in_email: false) }

        it 'returns false' do
          expect(group.show_diff_preview_in_email?).to be_falsey
        end
      end

      context 'when all parent groups have enabled diff previews' do
        let(:settings) { create(:namespace_settings, show_diff_preview_in_email: true) }

        it 'returns true' do
          expect(group.show_diff_preview_in_email?).to be_truthy
        end
      end
    end
  end

  describe '#emails_enabled?' do
    let_it_be_with_refind(:group) { create(:group) }

    it 'returns true when the attribute is true' do
      group.emails_enabled = true

      expect(group.emails_enabled?).to be_truthy
    end

    it 'returns false when the attribute is false' do
      group.emails_enabled = false

      expect(group.emails_enabled?).to be_falsey
    end

    context 'when a group has parent groups' do
      let_it_be(:grandparent) { create(:group) }
      let_it_be(:parent) { create(:group, parent: grandparent) }
      let_it_be_with_refind(:group) { create(:group, parent: parent) }

      it 'returns true when no parent has disabled emails' do
        expect(group.emails_enabled?).to be_truthy
      end

      context 'when grandparent emails are disabled' do
        it 'returns false' do
          grandparent.update!(emails_enabled: false)

          expect(group.emails_enabled?).to be_falsey
        end
      end

      context "when parent emails are disabled" do
        it 'returns false' do
          parent.update!(emails_enabled: false)

          expect(group.emails_enabled?).to be_falsey
        end
      end
    end
  end

  context 'runner registration settings' do
    shared_context 'with runner registration settings changing in hierarchy' do
      context 'when there are no parents' do
        it { is_expected.to be_truthy }

        context 'when no group can register runners' do
          before do
            stub_application_setting(valid_runner_registrars: [])
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'when there are parents' do
        let_it_be(:grandparent) { create(:group) }
        let_it_be(:parent)      { create(:group, parent: grandparent) }
        let_it_be(:group)       { create(:group, parent: parent) }

        before do
          grandparent.update!(runner_registration_enabled: grandparent_runner_registration_enabled)
        end

        context 'when a parent group has runner registration disabled' do
          let(:grandparent_runner_registration_enabled) { false }

          it { is_expected.to be_falsey }
        end

        context 'when all parent groups have runner registration enabled' do
          let(:grandparent_runner_registration_enabled) { true }

          it { is_expected.to be_truthy }
        end
      end
    end

    describe '#runner_registration_enabled?' do
      subject(:group_setting) { group.runner_registration_enabled? }

      let_it_be(:settings) { create(:namespace_settings) }
      let_it_be(:group) { create(:group, namespace_settings: settings) }

      before do
        group.update!(runner_registration_enabled: group_runner_registration_enabled)
      end

      context 'when runner registration is enabled' do
        let(:group_runner_registration_enabled) { true }

        it { is_expected.to be_truthy }

        it_behaves_like 'with runner registration settings changing in hierarchy'
      end

      context 'when runner registration is disabled' do
        let(:group_runner_registration_enabled) { false }

        it { is_expected.to be_falsey }

        it 'does not query the db' do
          expect { group.runner_registration_enabled? }.not_to exceed_query_limit(0)
        end

        context 'when group runner registration is disallowed' do
          before do
            stub_application_setting(valid_runner_registrars: [])
          end

          it { is_expected.to be_falsey }
        end
      end
    end

    describe '#all_ancestors_have_runner_registration_enabled?' do
      subject(:group_setting) { group.all_ancestors_have_runner_registration_enabled? }

      it_behaves_like 'with runner registration settings changing in hierarchy'
    end
  end

  describe '#allow_runner_registration_token?' do
    subject(:group_setting) { group.allow_runner_registration_token? }

    context 'when a top-level group' do
      let_it_be(:settings) { create(:namespace_settings) }
      let_it_be(:group) { create(:group, namespace_settings: settings) }

      before do
        group.update!(allow_runner_registration_token: allow_runner_registration_token)
      end

      context 'when :allow_runner_registration_token is false' do
        let(:allow_runner_registration_token) { false }

        it 'returns false', :aggregate_failures do
          is_expected.to be_falsey

          expect(settings.allow_runner_registration_token).to be_falsey
        end

        it 'does not query the db' do
          expect { group_setting }.not_to exceed_query_limit(0)
        end
      end

      context 'when :allow_runner_registration_token is true' do
        let(:allow_runner_registration_token) { true }

        it 'returns true', :aggregate_failures do
          is_expected.to be_truthy

          expect(settings.allow_runner_registration_token).to be_truthy
        end

        context 'when disallowed by application setting' do
          before do
            stub_application_setting(allow_runner_registration_token: false)
          end

          it { is_expected.to be_falsey }
        end
      end
    end

    context 'when a group has parent groups' do
      let_it_be_with_refind(:parent) { create(:group) }
      let_it_be_with_refind(:group) { create(:group, parent: parent) }

      before do
        parent.update!(allow_runner_registration_token: allow_runner_registration_token)
      end

      context 'when a parent group has runner registration disabled' do
        let(:allow_runner_registration_token) { false }

        it { is_expected.to be_falsey }
      end

      context 'when all parent groups have runner registration enabled' do
        let(:allow_runner_registration_token) { true }

        it { is_expected.to be_truthy }

        context 'when disallowed by application setting' do
          before do
            stub_application_setting(allow_runner_registration_token: false)
          end

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#math_rendering_limits_enabled' do
    it_behaves_like 'a cascading namespace setting boolean attribute', settings_attribute_name: :math_rendering_limits_enabled
  end

  describe '#resource_access_token_notify_inherited' do
    it_behaves_like 'a cascading namespace setting boolean attribute', settings_attribute_name: :resource_access_token_notify_inherited
  end

  describe '#web_based_commit_signing_enabled' do
    it_behaves_like 'a cascading namespace setting boolean attribute', settings_attribute_name: :web_based_commit_signing_enabled
  end

  describe 'default_branch_protection_defaults' do
    let(:defaults) { { name: 'main', push_access_level: 30, merge_access_level: 30, unprotect_access_level: 40 } }

    it 'returns the value for default_branch_protection_defaults' do
      subject.default_branch_protection_defaults = defaults
      expect(subject.default_branch_protection_defaults['name']).to eq('main')
      expect(subject.default_branch_protection_defaults['push_access_level']).to eq(30)
      expect(subject.default_branch_protection_defaults['merge_access_level']).to eq(30)
      expect(subject.default_branch_protection_defaults['unprotect_access_level']).to eq(40)
    end

    context 'when provided with content that does not match the JSON schema' do
      # valid json
      it { is_expected.to allow_value({ name: 'bar' }).for(:default_branch_protection_defaults) }

      # invalid json
      it { is_expected.not_to allow_value({ foo: 'bar' }).for(:default_branch_protection_defaults) }
    end
  end

  describe 'pipeline_variables_default_role' do
    subject { group.namespace_settings.pipeline_variables_default_role }

    context 'validations' do
      let(:namespace_settings) { build(:namespace_settings) }

      context 'when pipeline_variables_default_role is valid' do
        it 'does not add an error' do
          valid_roles = ProjectCiCdSetting::PIPELINE_VARIABLES_OVERRIDE_ROLES.keys.map(&:to_s)

          valid_roles.each do |role|
            namespace_settings.pipeline_variables_default_role = role
            expect(namespace_settings).to be_valid
          end
        end
      end
    end

    context 'when an invalid role is assigned to pipeline_variables_default_role' do
      it 'raises an ArgumentError' do
        expect do
          namespace_settings.pipeline_variables_default_role = 'invalid_role'
        end.to raise_error(ArgumentError, "'invalid_role' is not a valid pipeline_variables_default_role")
      end
    end

    context 'when namespace is root' do
      let(:group) { create(:group) }
      let(:variables_default_role) { group.namespace_settings.pipeline_variables_default_role }

      it { expect(variables_default_role).to eq('developer') }

      context 'when application setting `pipeline_variables_default_allowed` is false' do
        before do
          stub_application_setting(pipeline_variables_default_allowed: false)
        end

        it { expect(variables_default_role).to eq('no_one_allowed') }
      end
    end

    context 'when namespace is not root' do
      let(:root_group) { create(:group) }

      before do
        group.parent = root_group

        root_settings = group.parent.namespace_settings
        root_settings.pipeline_variables_default_role = 'maintainer'
      end

      it { is_expected.to eq('maintainer') }
    end
  end

  describe '#jwt_ci_cd_job_token_enabled?' do
    let(:settings) { described_class.new }

    subject(:jwt_ci_cd_job_token_enabled?) { settings.jwt_ci_cd_job_token_enabled? }

    where(:jwt_ci_cd_job_token_enabled, :feature_flag_enabled?, :jwt_ci_cd_job_token_opted_out, :jwt_enabled?) do
      false | false | false | false
      false | false | true  | false
      false | true  | false | true
      true  | false | false | true
      false | true  | true  | false
      true  | false | true  | true
      true  | true  | false | true
      true  | true  | true  | true
    end

    with_them do
      before do
        settings.jwt_ci_cd_job_token_enabled = jwt_ci_cd_job_token_enabled
        settings.jwt_ci_cd_job_token_opted_out = jwt_ci_cd_job_token_opted_out
        stub_feature_flags(ci_job_token_jwt: feature_flag_enabled?)
      end

      it { is_expected.to be(jwt_enabled?) }
    end
  end

  describe 'descendants cache invalidation' do
    context 'when cached record is present' do
      let_it_be_with_reload(:cache) { create(:namespace_descendants, namespace: group) }

      it 'invalidates the cache when archived changes to true' do
        expect { namespace_settings.update!(archived: true) }.to change { cache.reload.outdated_at }.from(nil)
      end

      it 'invalidates the cache when archived changes to false' do
        namespace_settings.update!(archived: true)
        cache.update!(outdated_at: nil) # reset cache to be valid again

        expect { namespace_settings.update!(archived: false) }.to change { cache.reload.outdated_at }.from(nil)
      end

      it 'does not invalidate cache when other attributes change' do
        expect { namespace_settings.update!(emails_enabled: true) }.not_to change { cache.reload.outdated_at }
      end
    end

    context 'when namespace is UserNamespace' do
      let(:user_namespace) { create(:user_namespace) }
      let!(:namespace_settings) { create(:namespace_settings, namespace: user_namespace) }
      let!(:cache) { create(:namespace_descendants, namespace: user_namespace) }

      it 'does not invalidate cache' do
        expect { user_namespace.namespace_settings.update!(archived: true) }.not_to change { cache.reload.outdated_at }
      end
    end

    context 'when parent group has cached record' do
      let(:parent_group) { create(:group) }
      let(:child_group) { create(:group, parent: parent_group) }
      let!(:parent_cache) { create(:namespace_descendants, namespace: parent_group) }

      it 'invalidates the parent cache when child is archived' do
        expect { child_group.namespace_settings.update!(archived: true) }.to change { parent_cache.reload.outdated_at }.from(nil)
      end
    end
  end

  describe '#step_up_auth_required_oauth_provider' do
    subject { namespace_settings }

    context 'without omniauth provider configured for step-up authentication' do
      it { is_expected.to validate_presence_of(:step_up_auth_required_oauth_provider).allow_nil }
      it { is_expected.to validate_inclusion_of(:step_up_auth_required_oauth_provider).in_array([]).allow_nil }
      it { is_expected.to nullify_if_blank(:step_up_auth_required_oauth_provider) }
    end

    context 'with omniauth providers configured for step-up authentication' do
      let(:ommiauth_provider_config_with_step_up_auth) do
        GitlabSettings::Options.new(
          name: "openid_connect",
          step_up_auth: {
            namespace: {
              id_token: {
                required: { acr: 'gold' }
              }
            }
          }
        )
      end

      before do
        stub_omniauth_setting(enabled: true, providers: [ommiauth_provider_config_with_step_up_auth])
        allow(Devise).to receive(:omniauth_providers).and_return([ommiauth_provider_config_with_step_up_auth.name])
      end

      it { is_expected.to validate_inclusion_of(:step_up_auth_required_oauth_provider).in_array([ommiauth_provider_config_with_step_up_auth.name]) }

      it { is_expected.to allow_value(ommiauth_provider_config_with_step_up_auth.name).for(:step_up_auth_required_oauth_provider) }
      it { is_expected.to allow_value('').for(:step_up_auth_required_oauth_provider) }
      it { is_expected.not_to allow_value('google_oauth2').for(:step_up_auth_required_oauth_provider).with_message('is not included in the list') }

      context 'when parent group defines step-up auth provider' do
        let_it_be_with_reload(:subsubgroup) { create(:group, parent: subgroup) }

        subject { subsubgroup.namespace_settings }

        before do
          group.namespace_settings.update!(step_up_auth_required_oauth_provider: 'openid_connect')
        end

        it { is_expected.not_to allow_value('openid_connect').for(:step_up_auth_required_oauth_provider).with_message("cannot be changed because it is inherited from parent group \"#{group.name}\"") }
        it { is_expected.to allow_value(nil).for(:step_up_auth_required_oauth_provider) }
      end
    end
  end

  describe '#step_up_auth_required_oauth_provider_inherited_namespace_setting and #step_up_auth_required_oauth_provider_from_self_or_inherited' do
    let_it_be_with_reload(:group) { group }
    let_it_be_with_reload(:subgroup) { subgroup }
    let_it_be_with_reload(:subsubgroup) { create(:group, parent: subgroup) }

    let(:step_up_provider_oidc) do
      GitlabSettings::Options.new(
        name: 'oidc',
        step_up_auth: {
          namespace: {
            id_token: {
              required: { acr: 'gold' }
            }
          }
        }
      )
    end

    let(:step_up_provider_oidc_aad) do
      GitlabSettings::Options.new(
        name: 'oidc_aad',
        step_up_auth: {
          namespace: {
            id_token: {
              required: {
                acr: 'gold'
              }
            }
          }
        }
      )
    end

    before do
      stub_omniauth_setting(enabled: true, providers: [step_up_provider_oidc, step_up_provider_oidc_aad])
      allow(Devise).to receive(:omniauth_providers).and_return([step_up_provider_oidc.name, step_up_provider_oidc_aad.name])

      subsubgroup.namespace_settings.update!(step_up_auth_required_oauth_provider: subsubgroup_step_up_provider)
      subgroup.namespace_settings.update!(step_up_auth_required_oauth_provider: subgroup_step_up_provider)
      group.namespace_settings.update!(step_up_auth_required_oauth_provider: group_step_up_provider)
    end

    where(:group_step_up_provider, :subgroup_step_up_provider, :subsubgroup_step_up_provider, :test_group, :expected_inherited_namespace, :expected_provider_from_self_or_inherited) do
      # Test inheritance precedence (most distant ancestor wins)
      'oidc_aad' | 'oidc' | nil    | ref(:subsubgroup) | ref(:group)    | 'oidc_aad'
      'oidc_aad' | nil    | nil    | ref(:subsubgroup) | ref(:group)    | 'oidc_aad'
      nil        | 'oidc' | nil    | ref(:subsubgroup) | ref(:subgroup) | 'oidc'

      # Test own value takes precedence over inheritance
      nil        | 'oidc' | 'oidc' | ref(:subsubgroup) | ref(:subgroup) | 'oidc'
      nil        | nil    | 'oidc' | ref(:subsubgroup) | nil            | 'oidc'

      # Test middle level inheritance
      'oidc_aad' | nil    | nil    | ref(:subgroup)    | ref(:group)    | 'oidc_aad'
      nil        | 'oidc' | nil    | ref(:subgroup)    | nil            | 'oidc'

      # Test root level (no inheritance possible)
      'oidc_aad' | nil    | nil    | ref(:group)       | nil            | 'oidc_aad'

      # Test no providers anywhere
      nil        | nil    | nil    | ref(:subsubgroup) | nil            | nil
      nil        | nil    | nil    | ref(:subgroup)    | nil            | nil
      nil        | nil    | nil    | ref(:group)       | nil            | nil
    end

    with_them do
      describe '#step_up_auth_required_oauth_provider_inherited_namespace_setting' do
        subject { test_group.namespace_settings.step_up_auth_required_oauth_provider_inherited_namespace_setting&.namespace }

        it { is_expected.to eq expected_inherited_namespace }
      end

      describe '#step_up_auth_required_oauth_provider_from_self_or_inherited' do
        subject { test_group.namespace_settings&.step_up_auth_required_oauth_provider_from_self_or_inherited }

        it { is_expected.to eq expected_provider_from_self_or_inherited }
      end
    end
  end
end
