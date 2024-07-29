# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSettings::AssignAttributesService, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:settings) { {} }

  subject(:service) { described_class.new(user, group, settings) }

  describe "#execute" do
    context "group has no namespace_settings" do
      before do
        group.namespace_settings.destroy!
      end

      it "builds out a new namespace_settings record" do
        expect do
          service.execute
        end.to change { NamespaceSetting.count }.by(1)
      end
    end

    context "group has a namespace_settings" do
      before do
        service.execute
      end

      it "doesn't create a new namespace_setting record" do
        expect do
          service.execute
        end.not_to change { NamespaceSetting.count }
      end
    end

    context "updating :default_branch_name" do
      let(:example_branch_name) { "example_branch_name" }
      let(:settings) { { default_branch_name: example_branch_name } }

      it "changes settings" do
        expect { service.execute }
          .to change { group.namespace_settings.default_branch_name }
                .from(nil).to(example_branch_name)
      end

      context 'when default branch name is invalid' do
        let(:settings) { { default_branch_name: '****' } }

        it "does not update the default branch" do
          expect { service.execute }.not_to change { group.namespace_settings.default_branch_name }

          expect(group.namespace_settings.errors[:default_branch_name]).to include('is invalid.')
        end
      end

      context 'when default branch name is changed to empty' do
        before do
          group.namespace_settings.update!(default_branch_name: 'main')
        end

        let(:settings) { { default_branch_name: '' } }

        it 'updates the default branch' do
          expect { service.execute }.to change { group.namespace_settings.default_branch_name }.from('main').to('')
        end
      end
    end

    context 'when default_branch_protection is updated' do
      let(:namespace_settings) { group.namespace_settings }
      let(:expected) { ::Gitlab::Access::BranchProtection.protected_against_developer_pushes.stringify_keys }
      let(:settings) { { default_branch_protection: ::Gitlab::Access::PROTECTION_DEV_CAN_MERGE } }

      context 'when the user has the ability to update' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :update_default_branch_protection, group).and_return(true)
        end

        context 'when group is root' do
          before do
            allow(group).to receive(:root?).and_return(true)
          end

          it "updates default_branch_protection_defaults from the default_branch_protection param" do
            expect { service.execute }
              .to change { namespace_settings.default_branch_protection_defaults }
                    .from(::Gitlab::Access::BranchProtection.protection_none.stringify_keys).to(expected)
          end
        end

        context 'when group is not root' do
          before do
            allow(group).to receive(:root?).and_return(false)
          end

          it "updates default_branch_protection_defaults from the default_branch_protection param" do
            expect { service.execute }
              .to change { namespace_settings.default_branch_protection_defaults }
                    .from(::Gitlab::Access::BranchProtection.protection_none.stringify_keys).to(expected)
          end
        end
      end

      context 'when the user does not have the ability to update' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :update_default_branch_protection, group).and_return(false)
        end

        it "does not update default_branch_protection_defaults and adds an error to the namespace_settings",
          :aggregate_failures do
          expect { service.execute }.not_to change { namespace_settings.default_branch_protection_defaults }
          expect(group.namespace_settings.errors[:default_branch_protection]).to include('can only be changed by a group admin.')
        end
      end
    end

    context 'when default_branch_protection_defaults is updated' do
      let(:namespace_settings) { group.namespace_settings }
      let(:branch_protection) { ::Gitlab::Access::BranchProtection.protected_against_developer_pushes.stringify_keys }
      let(:expected) { branch_protection }
      let(:settings) { { default_branch_protection_defaults: branch_protection } }

      context 'when the user has the ability to update' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :update_default_branch_protection, group).and_return(true)
        end

        context 'when group is root' do
          before do
            allow(group).to receive(:root?).and_return(true)
          end

          it "updates default_branch_protection_defaults from the default_branch_protection param" do
            expect { service.execute }
              .to change { namespace_settings.default_branch_protection_defaults }
                    .from(::Gitlab::Access::BranchProtection.protection_none.stringify_keys).to(expected)
          end
        end

        context 'when group is not root' do
          before do
            allow(group).to receive(:root?).and_return(false)
          end

          it "updates default_branch_protection_defaults from the default_branch_protection param" do
            expect { service.execute }
              .to change { namespace_settings.default_branch_protection_defaults }
                    .from(::Gitlab::Access::BranchProtection.protection_none.stringify_keys).to(expected)
          end
        end
      end

      context 'when the user does not have the ability to update' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :update_default_branch_protection, group).and_return(false)
        end

        it "does not update default_branch_protection_defaults and adds an error to the namespace_settings",
          :aggregate_failures do
          expect { service.execute }.not_to change { namespace_settings.default_branch_protection_defaults }
          expect(group.namespace_settings.errors[:default_branch_protection_defaults]).to include('can only be changed by a group admin.')
        end
      end
    end

    context 'when early_access_program_joined_by_id is updated' do
      let(:is_participating) { false }
      let!(:namespace_settings) do
        group.namespace_settings.update!(early_access_program_participant: is_participating)
        group.namespace_settings
      end

      context 'with true' do
        let(:settings) { { early_access_program_participant: true } }

        context 'with previously unset' do
          it 'sets early_access_program_joined_by' do
            expect { service.execute }
              .to change { namespace_settings.early_access_program_participant }.from(false).to(true)
              .and change { namespace_settings.early_access_program_joined_by_id }.from(nil).to(user.id)
          end
        end

        context 'with previously true' do
          let(:is_participating) { true }

          it "doesn't change early_access_program_joined_by" do
            expect { service.execute }
              .to not_change { namespace_settings.early_access_program_participant }
              .and not_change { namespace_settings.early_access_program_joined_by_id }
          end
        end
      end

      context 'with false' do
        let(:settings) { { early_access_program_participant: false } }

        context 'with previously unset' do
          it "doesn't change early_access_program_joined_by" do
            expect { service.execute }
              .to not_change { namespace_settings.early_access_program_participant }
              .and not_change { namespace_settings.early_access_program_joined_by_id }
          end
        end

        context 'with previously true' do
          let(:is_participating) { true }

          it "doesn't change early_access_program_joined_by" do
            expect { service.execute }
              .to change { namespace_settings.early_access_program_participant }.from(true).to(false)
              .and not_change { namespace_settings.early_access_program_joined_by_id }
          end
        end
      end
    end

    context "updating :resource_access_token_creation_allowed" do
      let(:settings) { { resource_access_token_creation_allowed: false } }

      context 'when user is a group owner' do
        before do
          group.add_owner(user)
        end

        it "changes settings" do
          expect { service.execute }
            .to change { group.namespace_settings.resource_access_token_creation_allowed }
                  .from(true).to(false)
        end
      end

      context 'when user is not a group owner' do
        before do
          group.add_developer(user)
        end

        it "does not change settings" do
          expect { service.execute }.not_to change { group.namespace_settings.resource_access_token_creation_allowed }
        end

        it 'returns the group owner error' do
          service.execute
          expect(group.namespace_settings.errors.messages[:resource_access_token_creation_allowed]).to include('can only be changed by a group admin.')
        end
      end
    end

    describe 'validating settings param for root group' do
      using RSpec::Parameterized::TableSyntax

      where(:setting_key, :setting_changes_from, :setting_changes_to) do
        :prevent_sharing_groups_outside_hierarchy | false | true
        :new_user_signups_cap | nil | 100
        :seat_control | 'off' | 'user_cap'
        :enabled_git_access_protocol | 'all' | 'ssh'
      end

      with_them do
        let(:settings) do
          { setting_key => setting_changes_to }
        end

        context 'when user is not a group owner' do
          before do
            group.add_maintainer(user)
          end

          it 'does not change settings' do
            expect { service.execute }.not_to change { group.namespace_settings.public_send(setting_key) }
          end

          it 'returns the group owner error' do
            service.execute

            expect(group.namespace_settings.errors.messages[setting_key]).to include('can only be changed by a group admin.')
          end
        end

        context 'with a subgroup' do
          let(:subgroup) { create(:group, parent: group) }

          before do
            group.add_owner(user)
          end

          it 'does not change settings' do
            service = described_class.new(user, subgroup, settings)

            expect { service.execute }.not_to change { group.namespace_settings.public_send(setting_key) }

            expect(subgroup.namespace_settings.errors.messages[setting_key]).to include('only available on top-level groups.')
          end
        end

        context 'when user is a group owner' do
          before do
            group.add_owner(user)
          end

          it 'changes settings' do
            expect { service.execute }
              .to change { group.namespace_settings.public_send(setting_key) }
                    .from(setting_changes_from).to(setting_changes_to)
          end
        end
      end
    end
  end
end
