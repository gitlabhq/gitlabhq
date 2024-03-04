# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe EnsureMemberRolesNamesUniq, feature_category: :permissions do
  let(:migration) { described_class.new }

  let(:namespaces) { table(:namespaces) }
  let(:member_roles) { table(:member_roles) }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }

  let!(:member_role_1) { member_roles.create!(name: 'foo', namespace_id: namespace.id, base_access_level: 10) }
  let!(:member_role_2) { member_roles.create!(name: 'other', namespace_id: namespace.id, base_access_level: 10) }
  let!(:member_role_3) { member_roles.create!(name: 'other', namespace_id: nil, base_access_level: 10) }
  let!(:member_role_4) { member_roles.create!(name: 'no namespace', namespace_id: nil, base_access_level: 10) }
  let!(:member_role_1_duplicated) do
    member_roles.create!(name: 'foo', namespace_id: namespace.id, base_access_level: 10)
  end

  let!(:member_role_4_duplicated) do
    member_roles.create!(name: 'no namespace', namespace_id: nil, base_access_level: 10)
  end

  describe '#up' do
    it 'updates the duplicated names with higher id', :aggregate_failures do
      migration.up

      expect(member_role_1.reload.name).to eq('foo')
      expect(member_role_1_duplicated.reload.name).to eq("foo (#{member_role_1_duplicated.id})")
      expect(member_role_2.reload.name).to eq('other')
      expect(member_role_3.reload.name).to eq('other')
      expect(member_role_4.reload.name).to eq('no namespace')
      expect(member_role_4_duplicated.reload.name).to eq("no namespace (#{member_role_4_duplicated.id})")

      migration.down
      migration.up

      expect(member_role_1.reload.name).to eq('foo')
      expect(member_role_1_duplicated.reload.name).to eq("foo (#{member_role_1_duplicated.id})")
      expect(member_role_2.reload.name).to eq('other')
      expect(member_role_3.reload.name).to eq('other')
      expect(member_role_4.reload.name).to eq('no namespace')
      expect(member_role_4_duplicated.reload.name).to eq("no namespace (#{member_role_4_duplicated.id})")
    end
  end
end
