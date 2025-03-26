# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DowngradeOrganizationOwners, feature_category: :organization do
  let(:migration) { described_class.new }

  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }
  let(:organization_users) { table(:organization_users) }
  let(:organization) { organizations.create!(name: 'Test', path: 'test') }
  let!(:another_user) { create_user }
  let!(:another_organization_user) do
    organization_users.create!(user_id: another_user.id, organization_id: organization.id, access_level: 50)
  end

  def create_user(params = {})
    user_params = {
      projects_limit: 10, username: FFaker::Internet.user_name, email: FFaker::Internet.email
    }.merge(params)

    users.create!(user_params)
  end

  describe '#up' do
    context 'when owner is found' do
      context 'and there is another owner' do
        let!(:another_organization_user) do
          organization_users.create!(user_id: another_user.id, organization_id: organization.id, access_level: 50)
        end

        context 'and owner is an admin' do
          let!(:user) { create_user(admin: true) }
          let!(:organization_user) do
            organization_users.create!(user_id: user.id, organization_id: organization.id, access_level: 50)
          end

          it 'does not revoke owner level' do
            expect { migrate! }.not_to change { organization_user.reload.access_level }
          end
        end

        context 'and owner is not an admin' do
          let!(:user) { create_user }
          let!(:organization_user) do
            organization_users.create!(user_id: user.id, organization_id: organization.id, access_level: 50)
          end

          it 'does revoke owner level' do
            expect { migrate! }.to change { organization_user.reload.access_level }.from(50).to(10)
          end
        end
      end
    end
  end
end
