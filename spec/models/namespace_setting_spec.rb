# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSetting, type: :model do
  # Relationships
  #
  describe "Associations" do
    it { is_expected.to belong_to(:namespace) }
  end

  describe "validations" do
    describe "#default_branch_name_content" do
      let_it_be(:group) { create(:group) }

      let(:namespace_settings) { group.namespace_settings }

      shared_examples "doesn't return an error" do
        it "doesn't return an error" do
          expect(namespace_settings.valid?).to be_truthy
          expect(namespace_settings.errors.full_messages).to be_empty
        end
      end

      context "when not set" do
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

      context "when it contains javascript tags" do
        it "gets sanitized properly" do
          namespace_settings.update!(default_branch_name: "hello<script>alert(1)</script>")

          expect(namespace_settings.default_branch_name).to eq('hello')
        end
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
    let!(:group) { create(:group, parent: parent, namespace_settings: settings ) }

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

  describe 'hooks related to group user cap update' do
    let(:settings) { create(:namespace_settings, new_user_signups_cap: user_cap) }
    let(:group) { create(:group, namespace_settings: settings) }

    before do
      allow(group).to receive(:root?).and_return(true)
    end

    context 'when updating a group with a user cap' do
      let(:user_cap) { nil }

      it 'also sets share_with_group_lock and prevent_sharing_groups_outside_hierarchy to true' do
        expect(group.new_user_signups_cap).to be_nil
        expect(group.share_with_group_lock).to be_falsey
        expect(settings.prevent_sharing_groups_outside_hierarchy).to be_falsey

        settings.update!(new_user_signups_cap: 10)
        group.reload

        expect(group.new_user_signups_cap).to eq(10)
        expect(group.share_with_group_lock).to be_truthy
        expect(settings.reload.prevent_sharing_groups_outside_hierarchy).to be_truthy
      end

      it 'has share_with_group_lock and prevent_sharing_groups_outside_hierarchy returning true for descendent groups' do
        descendent = create(:group, parent: group)
        desc_settings = descendent.namespace_settings

        expect(descendent.share_with_group_lock).to be_falsey
        expect(desc_settings.prevent_sharing_groups_outside_hierarchy).to be_falsey

        settings.update!(new_user_signups_cap: 10)

        expect(descendent.reload.share_with_group_lock).to be_truthy
        expect(desc_settings.reload.prevent_sharing_groups_outside_hierarchy).to be_truthy
      end
    end

    context 'when removing a user cap from namespace settings' do
      let(:user_cap) { 10 }

      it 'leaves share_with_group_lock and prevent_sharing_groups_outside_hierarchy set to true to the related group' do
        expect(group.share_with_group_lock).to be_truthy
        expect(settings.prevent_sharing_groups_outside_hierarchy).to be_truthy

        settings.update!(new_user_signups_cap: nil)

        expect(group.reload.share_with_group_lock).to be_truthy
        expect(settings.reload.prevent_sharing_groups_outside_hierarchy).to be_truthy
      end
    end
  end
end
