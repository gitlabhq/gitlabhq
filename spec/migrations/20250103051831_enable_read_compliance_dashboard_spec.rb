# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe EnableReadComplianceDashboard, feature_category: :permissions do
  let(:migration) { described_class.new }

  let(:member_roles) { table(:member_roles) }

  let!(:member_role_1) do
    member_roles.create!(name: 'Custom role 1', base_access_level: 10,
      permissions: { admin_compliance_framework: true })
  end

  let!(:member_role_2) do
    member_roles.create!(name: 'Custom role 2', base_access_level: 10,
      permissions: { admin_compliance_framework: false })
  end

  let!(:member_role_3) do
    member_roles.create!(name: 'Custom role 3', base_access_level: 10,
      permissions: { read_code: true, admin_compliance_framework: true })
  end

  describe '#up' do
    it 'adds read_compliance_dashboard when admin_compliance_framework is enabled', :aggregate_failures do
      expect { migration.up }
        .to change { member_role_1.reload.permissions['read_compliance_dashboard'] }.from(nil).to(true)
        .and change { member_role_3.reload.permissions['read_compliance_dashboard'] }.from(nil).to(true)
        .and not_change { member_role_2.reload.permissions['read_compliance_dashboard'] }.from(nil)
    end
  end
end
