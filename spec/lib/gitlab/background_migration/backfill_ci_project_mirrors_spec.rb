# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiProjectMirrors, :migration,
               :suppress_gitlab_schemas_validate_connection, schema: 20211208122201 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:ci_project_mirrors) { table(:ci_project_mirrors) }

  subject { described_class.new }

  describe '#perform' do
    it 'creates ci_project_mirrors for all projects in range' do
      namespaces.create!(id: 10, name: 'namespace1', path: 'namespace1')
      projects.create!(id: 5, namespace_id: 10, name: 'test1', path: 'test1')
      projects.create!(id: 7, namespace_id: 10, name: 'test2', path: 'test2')
      projects.create!(id: 8, namespace_id: 10, name: 'test3', path: 'test3')

      subject.perform(5, 7)

      expect(ci_project_mirrors.all).to contain_exactly(
        an_object_having_attributes(project_id: 5, namespace_id: 10),
        an_object_having_attributes(project_id: 7, namespace_id: 10)
      )
    end

    it 'handles existing ci_project_mirrors gracefully' do
      namespaces.create!(id: 10, name: 'namespace1', path: 'namespace1')
      namespaces.create!(id: 11, name: 'namespace2', path: 'namespace2', parent_id: 10)
      projects.create!(id: 5, namespace_id: 10, name: 'test1', path: 'test1')
      projects.create!(id: 7, namespace_id: 11, name: 'test2', path: 'test2')
      projects.create!(id: 8, namespace_id: 11, name: 'test3', path: 'test3')

      # Simulate a situation where a user has had a chance to move a project to another namespace
      # before the background migration has had a chance to run
      ci_project_mirrors.create!(project_id: 7, namespace_id: 10)

      subject.perform(5, 7)

      expect(ci_project_mirrors.all).to contain_exactly(
        an_object_having_attributes(project_id: 5, namespace_id: 10),
        an_object_having_attributes(project_id: 7, namespace_id: 10)
      )
    end
  end
end
