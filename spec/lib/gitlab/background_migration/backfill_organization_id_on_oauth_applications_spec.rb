# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOrganizationIdOnOauthApplications, feature_category: :system_access do
  describe '#perform' do
    let(:organizations_table) { table(:organizations) }
    let(:oauth_applications_table) { table(:oauth_applications) }
    let(:namespaces_table) { table(:namespaces) }
    let(:users_table) { table(:users) }

    let(:args) do
      min, max = oauth_applications_table.pick('MIN(id)', 'MAX(id)')

      {
        start_id: min,
        end_id: max,
        batch_table: 'oauth_applications',
        batch_column: 'id',
        sub_batch_size: 1,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      }
    end

    subject(:perform_migration) { described_class.new(**args).perform }

    context 'when organizations exist' do
      let!(:default_organization) { organizations_table.create!(name: 'Default Org', path: 'default') }
      let!(:group_organization) { organizations_table.create!(name: 'Group Org', path: 'group') }
      let!(:user_organization) { organizations_table.create!(name: 'User Org', path: 'user') }

      let!(:group) do
        namespaces_table.create!(
          name: 'Group',
          path: 'group',
          type: 'Group',
          organization_id: group_organization.id
        )
      end

      let!(:user) do
        users_table.create!(
          email: 'hi@example.com',
          username: 'hi',
          projects_limit: 10,
          organization_id: user_organization.id
        )
      end

      let!(:owned_by_instance) { create_oauth_application(name: 'Owned by Instance') }
      let!(:owned_by_group) do
        create_oauth_application(
          name: 'Owned by Group',
          owner_id: group.id,
          owner_type: 'Namespace'
        )
      end

      let!(:owned_by_user) { create_oauth_application(name: 'Owned by User', owner_id: user.id, owner_type: 'User') }

      it "updates organization_id for each record as expected" do
        expect { perform_migration }.to change { owned_by_instance.reload.organization_id }
          .from(nil).to(default_organization.id)
          .and change { owned_by_group.reload.organization_id }.from(nil).to(group_organization.id)
          .and change { owned_by_user.reload.organization_id }.from(nil).to(user_organization.id)
      end

      context 'when application already has organization_id set' do
        let!(:already_backfilled) do
          create_oauth_application(
            name: 'Already Backfilled',
            organization_id: user_organization.id
          )
        end

        it 'does not change existing organization_id' do
          expect { perform_migration }.not_to change { already_backfilled.reload.organization_id }
        end
      end
    end

    context 'when no organization exists' do
      let!(:instance_app_without_org) { create_oauth_application(name: 'Instance App No Org') }

      it 'does not update instance-owned applications' do
        expect { perform_migration }.not_to change { instance_app_without_org.reload.organization_id }
      end
    end
  end

  private

  def create_oauth_application(name:, owner_id: nil, owner_type: nil, organization_id: nil)
    oauth_applications_table.create!(
      name: name,
      owner_id: owner_id,
      owner_type: owner_type,
      organization_id: organization_id,
      uid: Doorkeeper::OAuth::Helpers::UniqueToken.generate,
      secret: Doorkeeper::OAuth::Helpers::UniqueToken.generate,
      redirect_uri: FFaker::Internet.http_url
    )
  end
end
