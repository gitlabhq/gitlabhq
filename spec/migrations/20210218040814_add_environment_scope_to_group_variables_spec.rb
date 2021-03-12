# frozen_string_literal: true

require 'spec_helper'
require_migration!('add_environment_scope_to_group_variables')

RSpec.describe AddEnvironmentScopeToGroupVariables do
  let(:migration) { described_class.new }
  let(:ci_group_variables) { table(:ci_group_variables) }
  let(:group) { table(:namespaces).create!(name: 'group', path: 'group') }

  def create_variable!(group, key:, environment_scope: '*')
    table(:ci_group_variables).create!(
      group_id: group.id,
      key: key,
      environment_scope: environment_scope
    )
  end

  describe '#down' do
    context 'group has variables with duplicate keys' do
      it 'deletes all but the first record' do
        migration.up

        remaining_variable = create_variable!(group, key: 'key')
        create_variable!(group, key: 'key', environment_scope: 'staging')
        create_variable!(group, key: 'key', environment_scope: 'production')

        migration.down

        expect(ci_group_variables.pluck(:id)).to eq [remaining_variable.id]
      end
    end

    context 'group does not have variables with duplicate keys' do
      it 'does not delete any records' do
        migration.up

        create_variable!(group, key: 'key')
        create_variable!(group, key: 'staging')
        create_variable!(group, key: 'production')

        expect { migration.down }.not_to change { ci_group_variables.count }
      end
    end
  end
end
