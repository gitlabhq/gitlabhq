# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Groups::TransferService, feature_category: :organization do
  let_it_be(:user) { create(:user) }
  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }
  let_it_be_with_refind(:group) { create(:group, organization: old_organization) }

  let(:service) { described_class.new(group: group, new_organization: new_organization, current_user: user) }

  before_all do
    group.add_owner(user)
    new_organization.add_owner(user)
  end

  describe '#execute' do
    context 'when transfer is successful' do
      let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
      let_it_be_with_refind(:nested_subgroup) { create(:group, parent: subgroup, organization: old_organization) }
      let_it_be_with_refind(:project) { create(:project, namespace: group, organization: old_organization) }
      let_it_be_with_refind(:subgroup_project) do
        create(:project, namespace: subgroup, organization: old_organization)
      end

      let_it_be_with_refind(:nested_project) do
        create(:project, namespace: nested_subgroup, organization: old_organization)
      end

      before do
        allow_next_instance_of(Organizations::Groups::TransferValidator) do |validator|
          allow(validator).to receive(:can_transfer?).and_return(true)
        end
      end

      it 'returns success ServiceResponse' do
        result = service.execute
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_success
      end

      it 'does not set error on successful transfer' do
        service.execute

        expect(service.error).to be_nil
      end

      it 'executes within a database transaction' do
        expect(Group).to receive(:transaction).and_call_original

        service.execute
      end

      it 'updates organization_id for group, all descendants and projects' do
        service.execute

        expect(group.reload.organization_id).to eq(new_organization.id)
        expect(subgroup.reload.organization_id).to eq(new_organization.id)
        expect(nested_subgroup.reload.organization_id).to eq(new_organization.id)

        expect(project.reload.organization_id).to eq(new_organization.id)
        expect(subgroup_project.reload.organization_id).to eq(new_organization.id)
        expect(nested_project.reload.organization_id).to eq(new_organization.id)

        expect(project.project_namespace.reload.organization_id).to eq(new_organization.id)
        expect(subgroup_project.project_namespace.reload.organization_id).to eq(new_organization.id)
        expect(nested_project.project_namespace.reload.organization_id).to eq(new_organization.id)
      end

      describe 'visibility level updates' do
        context 'when new organization has lower visibility than some groups/projects' do
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
          let_it_be_with_refind(:public_subgroup) do
            create(:group, :public, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_subgroup) do
            create(:group, :internal, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:private_subgroup) do
            create(:group, :private, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:public_project) do
            create(:project, :public, namespace: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_project) do
            create(:project, :internal, namespace: subgroup, organization: old_organization)
          end

          let_it_be_with_refind(:private_project) do
            create(:project, :private, namespace: group, organization: old_organization)
          end

          it 'updates visibility for groups with higher visibility than organization' do
            service.execute

            expect(public_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end

          it 'does not update visibility for groups with lower or equal visibility' do
            service.execute

            expect(private_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end

          it 'updates visibility for projects with higher visibility than organization' do
            service.execute

            expect(public_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end

          it 'updates visibility for project namespaces with higher visibility' do
            service.execute

            expect(public_project.project_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_project.project_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end

          it 'does not update visibility for projects with lower or equal visibility' do
            service.execute

            expect(private_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end
        end

        context 'when new organization has higher visibility than some groups/projects' do
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
          let_it_be_with_refind(:private_subgroup) do
            create(:group, :private, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_subgroup) do
            create(:group, :internal, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:private_project) do
            create(:project, :private, namespace: group, organization: old_organization)
          end

          it 'does not update visibility for groups with lower visibility' do
            service.execute

            expect(private_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
          end

          it 'does not update visibility for projects with lower visibility' do
            service.execute

            expect(private_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end
        end

        context 'when new organization has same visibility as groups/projects' do
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }
          let_it_be_with_refind(:internal_subgroup) do
            create(:group, :internal, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_project) do
            create(:project, :internal, namespace: group, organization: old_organization)
          end

          it 'does not update visibility for groups with equal visibility' do
            service.execute

            expect(internal_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
          end

          it 'does not update visibility for projects with equal visibility' do
            service.execute

            expect(internal_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
          end
        end
      end

      it 'logs successful transfer with correct payload' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: "Group was transferred to a new organization",
            group_path: group.full_path,
            group_id: group.id,
            new_organization_path: new_organization.full_path,
            new_organization_id: new_organization.id,
            error_message: nil
          )
        )

        service.execute
      end
    end

    context 'when transfer validation fails' do
      let(:validator_error) { "Transfer not allowed" }

      before do
        allow_next_instance_of(Organizations::Groups::TransferValidator) do |validator|
          allow(validator).to receive_messages(can_transfer?: false, error_message: validator_error)
        end
      end

      it 'returns error ServiceResponse' do
        result = service.execute
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
      end

      it 'sets formatted error message' do
        result = service.execute

        expect(result.message).to eq("Group organization transfer failed: #{validator_error}")
        expect(service.error).to eq("Group organization transfer failed: #{validator_error}")
      end

      it 'logs transfer error with correct payload' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          hash_including(
            message: "Group was not transferred to a new organization",
            group_path: group.full_path,
            group_id: group.id,
            new_organization_path: new_organization.full_path,
            new_organization_id: new_organization.id,
            error_message: validator_error
          )
        )

        service.execute
      end

      it 'does not update organization_id' do
        original_organization_id = group.organization_id

        service.execute

        expect(group.reload.organization_id).to eq(original_organization_id)
      end

      it 'does not update organization_id for projects' do
        project = create(:project, namespace: group, organization: old_organization)
        original_organization_id = project.organization_id

        service.execute

        expect(project.reload.organization_id).to eq(original_organization_id)
      end
    end
  end
end
