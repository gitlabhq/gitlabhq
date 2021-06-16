# frozen_string_literal: true

require 'spec_helper'
require_migration!('group_protected_environments_add_index_and_constraint')

RSpec.describe GroupProtectedEnvironmentsAddIndexAndConstraint do
  let(:migration) { described_class.new }
  let(:protected_environments) { table(:protected_environments) }
  let(:group) { table(:namespaces).create!(name: 'group', path: 'group') }
  let(:project) { table(:projects).create!(name: 'project', path: 'project', namespace_id: group.id) }

  describe '#down' do
    it 'deletes only group-level configurations' do
      migration.up

      project_protections = [
        protected_environments.create!(project_id: project.id, name: 'production'),
        protected_environments.create!(project_id: project.id, name: 'staging')
      ]
      protected_environments.create!(group_id: group.id, name: 'production')
      protected_environments.create!(group_id: group.id, name: 'staging')

      migration.down

      expect(protected_environments.pluck(:id))
        .to match_array project_protections.map(&:id)
    end
  end
end
