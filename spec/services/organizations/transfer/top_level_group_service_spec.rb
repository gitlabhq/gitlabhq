# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Transfer::TopLevelGroupService, :aggregate_failures, feature_category: :organization do
  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }
  let_it_be(:user) { create(:user, organization: old_organization) }
  let_it_be_with_refind(:group) { create(:group, organization: old_organization) }

  let(:groups_param) { group }
  let(:organization_param) { new_organization }
  let(:current_user_param) { user }
  let(:skip_authorization_param) { false }

  subject(:service) do
    described_class.new(
      groups: groups_param,
      new_organization: organization_param,
      current_user: current_user_param,
      skip_authorization: skip_authorization_param
    )
  end

  before_all do
    group.add_owner(user)
    new_organization.add_owner(user)
  end

  describe '#execute' do
    context 'when transfer is successful' do
      it 'returns success ServiceResponse' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_success
        expect(result.payload[:succeeded]).to match_array([group.id])
        expect(result.payload[:failed]).to be_empty
      end

      it 'updates organization_id for the top-level group only' do
        service.execute

        expect(group.reload.organization_id).to eq(new_organization.id)
        expect(group).to be_valid
      end

      context 'with subgroups and projects' do
        let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
        let_it_be_with_refind(:project) { create(:project, namespace: group, organization: old_organization) }

        it 'does not update organization_id for subgroups or projects' do
          service.execute

          expect(group.reload.organization_id).to eq(new_organization.id)
          expect(subgroup.reload.organization_id).to eq(old_organization.id)
          expect(project.reload.organization_id).to eq(old_organization.id)
        end
      end

      it 'logs the successful transfer' do
        allow(Gitlab::AppLogger).to receive(:info).and_call_original
        expect(Gitlab::AppLogger).to receive(:info).with(hash_including(
          message: "Top-level group was transferred to a new organization",
          group_path: group.full_path,
          group_id: group.id,
          new_organization_path: new_organization.full_path,
          new_organization_id: new_organization.id,
          error_message: nil
        )).and_call_original

        service.execute
      end

      context 'with multiple groups' do
        let_it_be_with_refind(:group2) { create(:group, organization: old_organization) }
        let_it_be_with_refind(:group3) { create(:group, organization: old_organization) }

        let(:groups_param) { [group, group2, group3] }

        before_all do
          group2.add_owner(user)
          group3.add_owner(user)
        end

        it 'transfers all groups successfully' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:succeeded]).to contain_exactly(group.id, group2.id, group3.id)
          expect(result.payload[:failed]).to be_empty
          expect(group.reload.organization_id).to eq(new_organization.id)
          expect(group2.reload.organization_id).to eq(new_organization.id)
          expect(group3.reload.organization_id).to eq(new_organization.id)
        end

        it 'logs each transfer' do
          allow(Gitlab::AppLogger).to receive(:info).and_call_original
          expect(Gitlab::AppLogger).to receive(:info).with(
            a_hash_including(message: "Top-level group was transferred to a new organization")
          ).at_least(3).times.and_call_original

          service.execute
        end
      end
    end

    context 'when transfer fails' do
      context 'when group is not a root group' do
        let_it_be(:parent_group) { create(:group, organization: old_organization) }
        let_it_be(:subgroup) { create(:group, parent: parent_group, organization: old_organization) }

        let(:groups_param) { subgroup }

        before_all do
          parent_group.add_owner(user)
        end

        it 'returns error ServiceResponse' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(s_('TransferOrganization|Failed to transfer 1 of 1 groups'))
          expect(result.payload[:failed][subgroup.id]).to eq(
            s_('TransferOrganization|Only top-level groups can be transferred to a different organization.')
          )
        end

        it 'does not update the group organization_id' do
          expect { service.execute }.not_to change { subgroup.reload.organization_id }
        end
      end

      context 'when new_organization is nil' do
        let(:organization_param) { nil }

        it 'returns error ServiceResponse' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(
            format(
              s_('TransferOrganization|Top-level group organization transfer failed: %{error_message}'),
              error_message: s_('TransferOrganization|Target organization must be specified.')
            )
          )
        end

        it 'does not update the group organization_id' do
          service.execute

          expect(group.reload.organization_id).to eq(old_organization.id)
        end
      end

      context 'when user does not have permission' do
        context 'when user is not a group owner' do
          let_it_be(:non_owner) { create(:user) }
          let_it_be(:org_for_non_owner) { create(:organization) }

          let(:organization_param) { org_for_non_owner }
          let(:current_user_param) { non_owner }

          before_all do
            org_for_non_owner.add_owner(non_owner)
          end

          it 'returns error ServiceResponse' do
            result = service.execute

            expect(result).to be_error
            expect(result.message).to eq(s_('TransferOrganization|Failed to transfer 1 of 1 groups'))
            expect(result.payload[:failed][group.id]).to eq(
              s_('TransferOrganization|You must be an owner of both the group and new organization.')
            )
          end
        end

        context 'when user is not an organization owner' do
          let_it_be(:group_only_owner) { create(:user) }
          let_it_be_with_refind(:another_group) { create(:group, organization: old_organization) }

          let(:groups_param) { another_group }
          let(:current_user_param) { group_only_owner }

          before_all do
            another_group.add_owner(group_only_owner)
          end

          it 'returns error ServiceResponse' do
            result = service.execute

            expect(result).to be_error
            expect(result.message).to eq(
              s_('TransferOrganization|You must be an owner of both the group and new organization.')
            )
            expect(another_group.reload.organization_id).to eq(old_organization.id)
          end
        end
      end

      context 'when any group in the batch is invalid' do
        let_it_be_with_refind(:group2) { create(:group, organization: old_organization) }
        let_it_be(:parent_group) { create(:group, organization: old_organization) }
        let_it_be(:subgroup) { create(:group, parent: parent_group, organization: old_organization) }

        let(:groups_param) { [group, group2, subgroup] }

        before_all do
          group2.add_owner(user)
          parent_group.add_owner(user)
        end

        it 'fails the entire transfer and transfers no groups' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(s_('TransferOrganization|Failed to transfer 1 of 3 groups'))
          expect(result.payload[:failed].keys).to contain_exactly(subgroup.id)
          expect(result.payload[:failed][subgroup.id]).to eq(
            s_('TransferOrganization|Only top-level groups can be transferred to a different organization.')
          )
          expect(group.reload.organization_id).to eq(old_organization.id)
          expect(group2.reload.organization_id).to eq(old_organization.id)
          expect(subgroup.reload.organization_id).to eq(old_organization.id)
        end
      end
    end

    context 'with batching' do
      let_it_be(:batched_groups) { create_list(:group, 7, :private, organization: old_organization) }

      let(:groups_param) { batched_groups }

      before_all do
        batched_groups.each { |g| g.add_owner(user) }
      end

      it 'processes groups in batches' do
        stub_const("#{described_class}::BATCH_SIZE", 3)
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:succeeded].size).to eq(7)
        expect(result.payload[:failed]).to be_empty
        batched_groups.each do |g|
          expect(g.reload.organization_id).to eq(new_organization.id)
        end
      end

      it 'avoids N+1 queries when authorizing groups' do
        control = ActiveRecord::QueryRecorder.new do
          described_class.new(
            groups: batched_groups.first(3), new_organization: new_organization, current_user: user
          ).execute
        end

        expect do
          described_class.new(
            groups: batched_groups.first(7), new_organization: new_organization, current_user: user
          ).execute
        end.not_to exceed_query_limit(control)
      end
    end

    context 'with skip_authorization: true' do
      let(:skip_authorization_param) { true }
      let_it_be(:unauthorized_user) { create(:user) }
      let_it_be_with_refind(:unauthorized_group) { create(:group, organization: old_organization) }

      let(:groups_param) { unauthorized_group }
      let(:current_user_param) { unauthorized_user }

      it 'transfers the group without checking permissions' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:succeeded]).to contain_exactly(unauthorized_group.id)
        expect(result.payload[:failed]).to be_empty
        expect(unauthorized_group.reload.organization_id).to eq(new_organization.id)
      end

      it 'still validates that group is a root group' do
        parent_group = create(:group, organization: old_organization)
        subgroup = create(:group, parent: parent_group, organization: old_organization)

        result = described_class.new(
          groups: subgroup,
          new_organization: new_organization,
          current_user: unauthorized_user,
          skip_authorization: true
        ).execute

        expect(result).to be_error
        expect(result.payload[:failed][subgroup.id]).to eq(
          s_('TransferOrganization|Only top-level groups can be transferred to a different organization.')
        )
        expect(subgroup.reload.organization_id).to eq(old_organization.id)
      end

      it 'transfers group even if already in target organization' do
        unauthorized_group.update!(organization: new_organization)

        result = service.execute

        expect(result).to be_success
        expect(result.payload[:succeeded]).to contain_exactly(unauthorized_group.id)
        expect(result.payload[:failed]).to be_empty
      end
    end
  end
end
