# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSetting, feature_category: :groups_and_projects, type: :model do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup, refind: true) { create(:group, parent: group) }
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

  describe '.for_namespaces' do
    let(:setting_1) { create(:namespace_settings, namespace: namespace_1) }
    let(:setting_2) { create(:namespace_settings, namespace: namespace_2) }
    let_it_be(:namespace_1) { create(:namespace) }
    let_it_be(:namespace_2) { create(:namespace) }

    it 'returns namespace setting for the given projects' do
      expect(described_class.for_namespaces(namespace_1)).to contain_exactly(setting_1)
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

      it { expect(described_class).to validate_jsonb_schema(['default_branch_protection_defaults']) }

      context 'when json is more than 1kb' do
        let(:byte_size) { 1.1.kilobytes }

        it { is_expected.not_to allow_value({ name: value }).for(:default_branch_protection_defaults) }
      end

      context 'when json less than 1kb' do
        let(:byte_size) { 0.5.kilobytes }

        it { is_expected.to allow_value({ name: value }).for(:default_branch_protection_defaults) }
      end
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

      it { expect(variables_default_role).to eq('no_one_allowed') }

      context 'when feature flag `change_namespace_default_role_for_pipeline_variables` is disabled' do
        before do
          stub_feature_flags(change_namespace_default_role_for_pipeline_variables: false)
        end

        it { expect(variables_default_role).to eq('developer') }
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
end
