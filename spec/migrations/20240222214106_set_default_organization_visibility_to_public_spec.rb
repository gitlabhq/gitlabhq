# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetDefaultOrganizationVisibilityToPublic, feature_category: :cell do
  let(:organizations) { table(:organizations) }
  let(:default_organization) do
    organizations.create!(
      id: described_class::DEFAULT_ORGANIZATION_ID,
      visibility_level: described_class::PRIVATE_VISIBILITY,
      name: 'default',
      path: 'path'
    )
  end

  let!(:organization) do
    organizations.create!(visibility_level: described_class::PRIVATE_VISIBILITY, name: 'name', path: 'another_path')
  end

  describe '#up' do
    context 'when default organization exists' do
      before do
        default_organization
      end

      it 'updates only the default organization visibility_level to public' do
        expect(default_organization.visibility_level).to eq(described_class::PRIVATE_VISIBILITY)

        migrate!

        expect(default_organization.reload.visibility_level).to eq(described_class::PUBLIC_VISIBILITY)
        expect(organization.reload.visibility_level).to eq(described_class::PRIVATE_VISIBILITY)
      end
    end

    context 'when default organization does not exist' do
      it 'does not error' do
        migrate!

        expect(organization.reload.visibility_level).to eq(described_class::PRIVATE_VISIBILITY)
      end
    end
  end

  describe '#down' do
    before do
      organization.update!(visibility_level: described_class::PUBLIC_VISIBILITY)
    end

    context 'when default organization exists' do
      before do
        default_organization
      end

      it 'updates only the default organization visibility_level to private' do
        migrate!

        expect(default_organization.reload.visibility_level).to eq(described_class::PUBLIC_VISIBILITY)

        schema_migrate_down!

        expect(default_organization.reload.visibility_level).to eq(described_class::PRIVATE_VISIBILITY)
        expect(organization.reload.visibility_level).to eq(described_class::PUBLIC_VISIBILITY)
      end
    end

    context 'when default organization does not exist' do
      it 'does not error' do
        schema_migrate_down!

        expect(organization.reload.visibility_level).to eq(described_class::PUBLIC_VISIBILITY)
      end
    end
  end
end
