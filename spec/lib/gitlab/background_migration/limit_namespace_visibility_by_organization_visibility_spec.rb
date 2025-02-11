# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::LimitNamespaceVisibilityByOrganizationVisibility, feature_category: :groups_and_projects do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }

  let(:start_id) { namespaces.minimum(:id) }
  let(:end_id) { namespaces.maximum(:id) }

  let!(:default_organization) do
    organizations.create!(id: 1, name: 'Default', path: 'default', visibility_level: Gitlab::VisibilityLevel::PUBLIC)
  end

  let!(:public_organization) do
    organizations.create!(name: 'public-org', path: 'public-org', visibility_level: Gitlab::VisibilityLevel::PUBLIC)
  end

  let!(:private_organization) do
    organizations.create!(name: 'private-org', path: 'private-org', visibility_level: Gitlab::VisibilityLevel::PRIVATE)
  end

  subject(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    context 'when namespaces have higher visibility than their organizations' do
      let!(:private_org_public_namespace) do
        namespaces.create!(
          name: 'private-org-public-namespace',
          path: 'private-org-public-namespace',
          organization_id: private_organization.id,
          visibility_level: Gitlab::VisibilityLevel::PUBLIC
        )
      end

      let!(:private_org_internal_namespace) do
        namespaces.create!(
          name: 'private-org-internal-namespace',
          path: 'private-org-internal-namespace',
          organization_id: private_organization.id,
          visibility_level: Gitlab::VisibilityLevel::INTERNAL
        )
      end

      let!(:private_org_private_namespace) do
        namespaces.create!(
          name: 'private-org-private-namespace',
          path: 'private-org-private-namespace',
          organization_id: private_organization.id,
          visibility_level: Gitlab::VisibilityLevel::PRIVATE
        )
      end

      it 'updates namespace visibility levels to match organization visibility levels' do
        migration.perform

        visibility_levels = [
          namespaces.find(private_org_public_namespace.id),
          namespaces.find(private_org_internal_namespace.id),
          namespaces.find(private_org_private_namespace.id)
        ].map(&:visibility_level)

        expect(visibility_levels).to all(eq(Gitlab::VisibilityLevel::PRIVATE))
      end
    end

    context 'when namespaces have lower or equal visibility to their organizations' do
      let!(:public_org_public_namespace) do
        namespaces.create!(
          name: 'public-org-public-namespace',
          path: 'public-org-public-namespace',
          organization_id: public_organization.id,
          visibility_level: Gitlab::VisibilityLevel::PUBLIC
        )
      end

      let!(:private_org_private_namespace) do
        namespaces.create!(
          name: 'private-org-private-namespace',
          path: 'private-org-private-namespace',
          organization_id: private_organization.id,
          visibility_level: Gitlab::VisibilityLevel::PRIVATE
        )
      end

      it 'does not change namespace visibility levels' do
        migration.perform

        expect(namespaces.find(public_org_public_namespace.id).visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
        expect(namespaces.find(private_org_private_namespace.id).visibility_level)
          .to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end

    context 'when namespaces have default organization_id' do
      let!(:default_org_public_namespace) do
        namespaces.create!(
          name: 'default-org-public-namespace',
          path: 'default-org-public-namespace',
          organization_id: default_organization.id,
          visibility_level: Gitlab::VisibilityLevel::PUBLIC
        )
      end

      let!(:default_org_internal_namespace) do
        namespaces.create!(
          name: 'default-org-internal-namespace',
          path: 'default-org-internal-namespace',
          organization_id: default_organization.id,
          visibility_level: Gitlab::VisibilityLevel::INTERNAL
        )
      end

      let!(:default_org_private_namespace) do
        namespaces.create!(
          name: 'default-org-private-namespace',
          path: 'default-org-private-namespace',
          organization_id: default_organization.id,
          visibility_level: Gitlab::VisibilityLevel::PRIVATE
        )
      end

      it 'does not change namespace visibility levels' do
        migration.perform

        visibility_levels = [
          namespaces.find(default_org_public_namespace.id),
          namespaces.find(default_org_internal_namespace.id),
          namespaces.find(default_org_private_namespace.id)
        ].map(&:visibility_level)

        expect(visibility_levels).to eq(
          [
            Gitlab::VisibilityLevel::PUBLIC,
            Gitlab::VisibilityLevel::INTERNAL,
            Gitlab::VisibilityLevel::PRIVATE
          ]
        )
      end
    end

    context 'when namespaces have private visibility' do
      let!(:private_org_private_namespace) do
        namespaces.create!(
          name: 'private-org-private-namespace',
          path: 'private-org-private-namespace',
          organization_id: private_organization.id,
          visibility_level: Gitlab::VisibilityLevel::PRIVATE
        )
      end

      it 'does not change namespace visibility levels' do
        migration.perform

        expect(namespaces.find(private_org_private_namespace.id).visibility_level)
          .to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end
  end
end
