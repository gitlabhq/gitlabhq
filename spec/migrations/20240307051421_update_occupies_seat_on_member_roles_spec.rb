# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateOccupiesSeatOnMemberRoles, feature_category: :system_access do
  let(:member_roles) { table(:member_roles) }

  let!(:guest_member_role) do
    member_roles.create!(
      name: 'Guest member role',
      base_access_level: 10,
      read_code: true
    )
  end

  let!(:guest_plus_member_role) do
    member_roles.create!(
      name: 'Guest+ member role',
      base_access_level: 10,
      read_vulnerability: true
    )
  end

  let!(:reporter_member_role) do
    member_roles.create!(
      name: 'Reporter member role',
      base_access_level: 20,
      read_code: true
    )
  end

  describe '#up' do
    it 'updates occupies_seat to true for guest+ member roles' do
      migrate!

      expect(member_roles.pluck(:id, :occupies_seat)).to contain_exactly(
        [guest_member_role.id, false],
        [guest_plus_member_role.id, true],
        [reporter_member_role.id, true]
      )
    end
  end

  describe '#down' do
    it 'updates occupies_seat to false for all member roles' do
      migrate!
      schema_migrate_down!

      expect(member_roles.pluck(:id, :occupies_seat)).to contain_exactly(
        [guest_member_role.id, false],
        [guest_plus_member_role.id, false],
        [reporter_member_role.id, false]
      )
    end
  end
end
