# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Groups::UpdateTwoFactorRequirementService, feature_category: :system_access do
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:user) { create(:user) }

  subject(:execute) { described_class.new(group: group).execute }

  describe '#execute' do
    it 'returns a success response with the recalculated member count', :aggregate_failures do
      group.add_member(user, GroupMember::OWNER)

      expect(execute).to be_success
      expect(execute.payload[:recalculated_count]).to eq(1)
    end

    it 'excludes members whose user fails to save from the count' do
      group.add_member(user, GroupMember::OWNER)
      invalid_user = create(:user)
      group.add_member(invalid_user, GroupMember::DEVELOPER)
      invalid_user.update_columns(email: '')

      expect(execute.payload[:recalculated_count]).to eq(1)
    end

    context 'for group membership' do
      it 'enables two_factor_requirement for group members' do
        group.add_member(user, GroupMember::OWNER)
        group.update!(require_two_factor_authentication: true)

        execute

        expect(user.reload.require_two_factor_authentication_from_group).to be_truthy
      end

      it 'disables two_factor_requirement for group members' do
        user.update!(require_two_factor_authentication_from_group: true)
        group.add_member(user, GroupMember::OWNER)

        execute

        expect(user.reload.require_two_factor_authentication_from_group).to be_falsey
      end
    end

    context 'for sub groups and projects' do
      context 'with expanded group members' do
        let(:indirect_user) { create(:user) }

        context 'when two_factor_requirement is enabled' do
          context 'when two_factor_requirement is also enabled for ancestor group' do
            it 'enables two_factor_requirement for subgroup member' do
              subgroup = create(:group, :nested, parent: group)
              subgroup.add_member(indirect_user, GroupMember::OWNER)
              group.update!(require_two_factor_authentication: true)

              execute

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_truthy
            end
          end

          context 'when two_factor_requirement is disabled for ancestor group' do
            it 'enables two_factor_requirement for subgroup member' do
              subgroup = create(:group, :nested, parent: group, require_two_factor_authentication: true)
              subgroup.add_member(indirect_user, GroupMember::OWNER)
              group.update!(require_two_factor_authentication: false)

              execute

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_truthy
            end

            it 'enables two_factor_requirement for ancestor group member' do
              ancestor_group = create(:group)
              ancestor_group.add_member(indirect_user, GroupMember::OWNER)
              group.update!(parent: ancestor_group)
              group.update!(require_two_factor_authentication: true)

              execute

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_truthy
            end
          end
        end

        context 'when two_factor_requirement is disabled' do
          context 'when two_factor_requirement is enabled for ancestor group' do
            it 'enables two_factor_requirement for subgroup member' do
              subgroup = create(:group, :nested, parent: group)
              subgroup.add_member(indirect_user, GroupMember::OWNER)
              group.update!(require_two_factor_authentication: true)

              execute

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_truthy
            end
          end

          context 'when two_factor_requirement is also disabled for ancestor group' do
            it 'disables two_factor_requirement for subgroup member' do
              create(:group, :nested, parent: group, owners: indirect_user)
              group.update!(require_two_factor_authentication: false)

              execute

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_falsey
            end

            it 'disables two_factor_requirement for ancestor group member' do
              ancestor_group = create(:group, require_two_factor_authentication: false, owners: indirect_user)
              group.update!(parent: ancestor_group)
              indirect_user.update!(require_two_factor_authentication_from_group: true)
              group.update!(require_two_factor_authentication: false)

              execute

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_falsey
            end
          end
        end
      end

      context 'with project members' do
        it 'does not enable two_factor_requirement for child project member' do
          create(:project, group: group, maintainers: user)
          group.update!(require_two_factor_authentication: true)

          execute

          expect(user.reload.require_two_factor_authentication_from_group).to be_falsey
        end

        it 'does not enable two_factor_requirement for subgroup child project member' do
          subgroup = create(:group, :nested, parent: group)
          create(:project, group: subgroup, maintainers: user)
          group.update!(require_two_factor_authentication: true)

          execute

          expect(user.reload.require_two_factor_authentication_from_group).to be_falsey
        end
      end
    end
  end

  describe '#include_minimal_access?' do
    it 'is false' do
      method = described_class.instance_method(:include_minimal_access?)
      method = method.super_method until method.owner == described_class

      expect(method.bind_call(described_class.new(group: group))).to be(false)
    end
  end
end
