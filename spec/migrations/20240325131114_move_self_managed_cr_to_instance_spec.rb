# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe MoveSelfManagedCrToInstance, feature_category: :permissions do
  let(:migration) { described_class.new }

  let(:namespaces) { table(:namespaces) }
  let(:member_roles) { table(:member_roles) }

  let(:group_1) { namespaces.create!(name: 'Group 1', path: 'group1') }
  let(:group_dupl) { namespaces.create!(name: 'Group 1', path: 'group_duplicated') }
  let(:group_2) { namespaces.create!(name: 'Other group', path: 'other_group') }

  let!(:group_1_role_1) { member_roles.create!(name: 'foo', namespace_id: group_1.id, base_access_level: 10) }
  let!(:group_1_role_2) { member_roles.create!(name: 'other role', namespace_id: group_1.id, base_access_level: 10) }
  let!(:group_dupl_role_1) { member_roles.create!(name: 'foo', namespace_id: group_dupl.id, base_access_level: 10) }
  let!(:group_2_role) { member_roles.create!(name: 'foo', namespace_id: group_2.id, base_access_level: 10) }
  let!(:instance_role) { member_roles.create!(name: 'foo', namespace_id: nil, base_access_level: 10) }

  describe '#up' do
    context 'when on self managed' do
      it 'sets namespace_id to nil and updates name', :aggregate_failures do
        migration.up

        expect(group_1_role_1.reload.name).to eq("foo (Group 1 - #{group_1.id})")
        expect(group_1_role_1.namespace_id).to be_nil
        expect(group_1_role_2.reload.name).to eq("other role (Group 1 - #{group_1.id})")
        expect(group_1_role_2.namespace_id).to be_nil
        expect(group_dupl_role_1.reload.name).to eq("foo (Group 1 - #{group_dupl.id})")
        expect(group_dupl_role_1.namespace_id).to be_nil
        expect(group_2_role.reload.name).to eq("foo (Other group - #{group_2.id})")
        expect(group_2_role.namespace_id).to be_nil
        expect(instance_role.reload.name).to eq('foo') # no update for instance-level role
        expect(instance_role.namespace_id).to be_nil
      end
    end

    context 'when on SaaS', :saas do
      it 'does not update the custom roles', :aggregate_failures do
        migration.up

        expect(group_1_role_1.reload.name).to eq('foo')
        expect(group_1_role_1.namespace_id).to eq(group_1.id)
        expect(group_1_role_2.reload.name).to eq('other role')
        expect(group_1_role_2.namespace_id).to eq(group_1.id)
        expect(group_2_role.reload.name).to eq('foo')
        expect(group_2_role.namespace_id).to eq(group_2.id)
        expect(instance_role.reload.name).to eq('foo')
        expect(instance_role.namespace_id).to be_nil
      end
    end
  end
end
