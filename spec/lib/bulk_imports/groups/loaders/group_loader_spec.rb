# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Loaders::GroupLoader, feature_category: :importers do
  describe '#load' do
    let_it_be(:organization, freeze: false) { create(:organization) }
    let_it_be(:user, freeze: false) { create(:user, owner_of: organization) }
    let_it_be(:bulk_import, freeze: false) { create(:bulk_import, user: user, organization: organization) }
    let_it_be_with_reload(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }
    let_it_be(:tracker, freeze: false) { create(:bulk_import_tracker, entity: entity) }
    let_it_be(:context, freeze: false) { BulkImports::Pipeline::Context.new(tracker) }
    let_it_be(:destination_group, freeze: false) { create(:group, organization: organization, path: entity.destination_namespace) }

    let(:service_double) { instance_double(::Groups::CreateService) }
    let(:data) { { 'path' => 'test' } }
    let(:create_group_params) { data.merge('organization_id' => organization.id) }

    subject { described_class.new }

    context 'when path is missing' do
      it 'raises an error' do
        expect { subject.load(context, {}) }.to raise_error(described_class::GroupCreationError, 'Path is missing')
      end
    end

    context 'when destination namespace is not a group' do
      it 'raises an error' do
        entity.update!(destination_namespace: user.namespace.path)

        expect { subject.load(context, create_group_params) }.to raise_error(described_class::GroupCreationError, 'Destination is not a group')
      end
    end

    context 'when there are other group errors' do
      it 'raises an error with those errors' do
        entity.update!(destination_namespace: '')
        group = ::Group.new
        group.validate
        expected_errors = group.errors.full_messages.to_sentence
        service_response = ServiceResponse.error(message: '_error_', payload: { group: group })

        expect(::Groups::CreateService)
          .to receive(:new)
          .with(context.current_user, data)
          .and_return(service_double)

        expect(service_double).to receive(:execute).and_return(service_response)
        expect(entity).not_to receive(:update!)

        expect { subject.load(context, data) }.to raise_error(described_class::GroupCreationError, expected_errors)
      end
    end

    context 'when user can create group' do
      shared_examples 'calls Group Create Service to create a new group' do
        it 'calls Group Create Service to create a new group' do
          group_double = instance_double(::Group)
          service_response = ServiceResponse.success(payload: { group: group_double })

          expect(::Groups::CreateService)
            .to receive(:new)
            .with(context.current_user, create_group_params)
            .and_return(service_double)

          expect(service_double).to receive(:execute).and_return(service_response)
          expect(entity).to receive(:update!).with(group: group_double, organization: nil)

          subject.load(context, data)
        end
      end

      context 'when there is no parent group' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :create_group).and_return(true)
        end

        include_examples 'calls Group Create Service to create a new group'
      end

      context 'when there is parent group' do
        let(:parent) { create(:group, organization: organization) }
        let(:data) { { 'parent_id' => parent.id, 'path' => 'test' } }

        before do
          allow(Ability).to receive(:allowed?).with(user, :create_subgroup, parent).and_return(true)
        end

        include_examples 'calls Group Create Service to create a new group'
      end

      context 'when destination_namespace is not set' do
        let(:create_group_params) { data.merge('organization_id' => user.namespace.organization_id) }

        before do
          entity.update!(destination_namespace: '')
        end

        include_examples 'calls Group Create Service to create a new group'
      end

      # A subgroup path can exist in two organizations at once (top-level routes are
      # globally unique, subgroup full paths under distinct parents are not), so this is
      # the realistic shape of a cross-organization destination collision.
      context 'when a same-path namespace exists in both the import and another organization' do
        let(:colliding_path) { 'colliding-subgroup' }

        before do
          allow(Ability).to receive(:allowed?).with(user, :create_group).and_return(true)

          in_org_parent = create(:group, organization: organization)
          in_org_group = create(:group, parent: in_org_parent, path: colliding_path)

          foreign_organization = create(:organization)
          foreign_parent = create(:group, organization: foreign_organization)
          create(:group, parent: foreign_parent, path: colliding_path)

          entity.update!(destination_namespace: in_org_group.full_path)
        end

        it 'resolves the destination organization from the import organization, not the foreign one' do
          group_double = instance_double(::Group)
          service_response = ServiceResponse.success(payload: { group: group_double })

          expect(::Groups::CreateService)
            .to receive(:new)
            .with(context.current_user, data.merge('organization_id' => organization.id))
            .and_return(service_double)

          expect(service_double).to receive(:execute).and_return(service_response)
          allow(entity).to receive(:update!)

          subject.load(context, data)
        end
      end

      context 'when user does not have 2FA enabled' do
        before do
          allow(user).to receive(:two_factor_enabled?).and_return(false)
        end

        context 'when require_two_factor_authentication is not passed' do
          include_examples 'calls Group Create Service to create a new group'
        end

        context 'when require_two_factor_authentication is false' do
          let(:data) { { 'require_two_factor_authentication' => false, 'path' => 'test' } }

          include_examples 'calls Group Create Service to create a new group'
        end

        context 'when require_two_factor_authentication is true' do
          let(:data) { { 'require_two_factor_authentication' => true, 'path' => 'test' } }

          it 'does not create new group' do
            expect(::Groups::CreateService).not_to receive(:new)

            expect { subject.load(context, data) }
              .to raise_error(described_class::GroupCreationError, 'User requires Two-Factor Authentication')
          end
        end
      end
    end

    context 'when user cannot create group' do
      shared_examples 'does not create new group' do
        it 'does not create new group' do
          expect(::Groups::CreateService).not_to receive(:new)

          expect { subject.load(context, data) }.to raise_error(described_class::GroupCreationError, 'User not allowed to create group')
        end
      end

      context 'when there is no parent group' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :create_group).and_return(false)
        end

        include_examples 'does not create new group'
      end

      context 'when there is parent group' do
        let(:parent) { create(:group) }
        let(:data) { { 'parent_id' => parent.id, 'path' => 'test' } }

        before do
          allow(Ability).to receive(:allowed?).with(user, :create_subgroup, parent).and_return(false)
        end

        include_examples 'does not create new group'
      end
    end
  end
end
