# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSetting, type: :model do
  it_behaves_like 'sanitizable', :namespace_settings, %i[default_branch_name]

  # Relationships
  #
  describe "Associations" do
    it { is_expected.to belong_to(:namespace) }
  end

  it { is_expected.to define_enum_for(:jobs_to_be_done).with_values([:basics, :move_repository, :code_storage, :exploring, :ci, :other]).with_suffix }

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
end
