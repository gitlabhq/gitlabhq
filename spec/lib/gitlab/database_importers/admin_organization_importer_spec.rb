# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::AdminOrganizationImporter, feature_category: :organization do
  describe '.organization_for_admin' do
    context 'when the default organization exists' do
      # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- exercising the default-organization (legacy cell) path
      let_it_be(:default_organization) { create(:organization, :default) }
      # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization

      it 'returns the default organization without creating a new one', :aggregate_failures do
        expect { described_class.organization_for_admin }.not_to change { Organizations::Organization.count }

        expect(described_class.organization_for_admin).to eq(default_organization)
      end
    end

    context 'when the default organization does not exist' do
      before do
        stub_config_cell(id: 2)
      end

      it 'creates a new active, public organization that is not the default', :aggregate_failures do
        expect { described_class.organization_for_admin }.to change { Organizations::Organization.count }.by(1)

        organization = Organizations::Organization.order(:id).last
        expect(organization).not_to be_default
        expect(organization).to be_public
        expect(organization).to be_active
      end

      context 'when the organization env vars are not set' do
        it 'derives a cell-scoped path and name', :aggregate_failures do
          organization = described_class.organization_for_admin

          expect(organization.path).to match(/\Aadmin-org-cell-2-\h{8}\z/)
          expect(organization.name).to match(/\AAdmin org cell-2-\h{8}\z/)
        end
      end

      context 'when the organization env vars are set' do
        before do
          stub_env('GITLAB_ROOT_ORG_PATH' => 'cell-2-admin')
          stub_env('GITLAB_ROOT_ORG_NAME' => 'Cell 2 Admin')
        end

        it 'uses them for the path and name', :aggregate_failures do
          organization = described_class.organization_for_admin

          expect(organization.path).to eq('cell-2-admin')
          expect(organization.name).to eq('Cell 2 Admin')
        end
      end
    end
  end

  describe '.default_username_for' do
    context 'when the organization is the default organization' do
      # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- exercising the default-organization (legacy cell) path
      let_it_be(:organization) { create(:organization, :default) }
      # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization

      it 'returns the root username' do
        expect(described_class.default_username_for(organization)).to eq('root')
      end
    end

    context 'when the organization is not the default organization' do
      let_it_be(:organization) { create(:organization) }

      before do
        stub_config_cell(id: 2)
      end

      it 'derives a cell-scoped username' do
        expect(described_class.default_username_for(organization)).to match(/\Aroot-cell-2-\h{8}\z/)
      end
    end
  end
end
