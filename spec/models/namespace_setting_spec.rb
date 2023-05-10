# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSetting, feature_category: :subgroups, type: :model do
  it_behaves_like 'sanitizable', :namespace_settings, %i[default_branch_name]

  # Relationships
  #
  describe "Associations" do
    it { is_expected.to belong_to(:namespace) }
  end

  it { is_expected.to define_enum_for(:jobs_to_be_done).with_values([:basics, :move_repository, :code_storage, :exploring, :ci, :other]).with_suffix }
  it { is_expected.to define_enum_for(:enabled_git_access_protocol).with_values([:all, :ssh, :http]).with_suffix }

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:code_suggestions).in_array([true, false]) }

    describe "#default_branch_name_content" do
      let_it_be(:group) { create(:group) }

      subject(:namespace_settings) { group.namespace_settings }

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

    describe '#allow_mfa_for_group' do
      let(:settings) {  group.namespace_settings }

      context 'group is top-level group' do
        let(:group) { create(:group) }

        it 'is valid' do
          settings.allow_mfa_for_subgroups = false

          expect(settings).to be_valid
        end
      end

      context 'group is a subgroup' do
        let(:group) { create(:group, parent: create(:group)) }

        it 'is invalid' do
          settings.allow_mfa_for_subgroups = false

          expect(settings).to be_invalid
        end
      end
    end

    describe '#allow_resource_access_token_creation_for_group' do
      let(:settings) { group.namespace_settings }

      context 'group is top-level group' do
        let(:group) { create(:group) }

        it 'is valid' do
          settings.resource_access_token_creation_allowed = false

          expect(settings).to be_valid
        end
      end

      context 'group is a subgroup' do
        let(:group) { create(:group, parent: create(:group)) }

        it 'is invalid when resource access token creation is not enabled' do
          settings.resource_access_token_creation_allowed = false

          expect(settings).to be_invalid
          expect(group.namespace_settings.errors.messages[:resource_access_token_creation_allowed]).to include("is not allowed since the group is not top-level group.")
        end

        it 'is valid when resource access tokens are enabled' do
          settings.resource_access_token_creation_allowed = true

          expect(settings).to be_valid
        end
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

    describe '#emails_enabled?' do
      context 'when a group has no parent'
      let(:settings) { create(:namespace_settings, emails_enabled: true) }
      let(:grandparent) { create(:group) }
      let(:parent)      { create(:group, parent: grandparent) }
      let(:group)       { create(:group, parent: parent, namespace_settings: settings) }

      context 'when the groups setting is changed' do
        it 'returns false when the attribute is false' do
          group.update_attribute(:emails_disabled, true)

          expect(group.emails_enabled?).to be_falsey
        end
      end

      context 'when a group has a parent' do
        it 'returns true when no parent has disabled emails' do
          expect(group.emails_enabled?).to be_truthy
        end

        context 'when ancestor emails are disabled' do
          it 'returns false' do
            grandparent.update_attribute(:emails_disabled, true)

            expect(group.emails_enabled?).to be_falsey
          end
        end
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

  context 'runner registration settings' do
    shared_context 'with runner registration settings changing in hierarchy' do
      context 'when there are no parents' do
        let_it_be(:group) { create(:group) }

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

  describe '#delayed_project_removal' do
    it_behaves_like 'a cascading namespace setting boolean attribute', settings_attribute_name: :delayed_project_removal
  end
end
