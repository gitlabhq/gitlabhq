# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiNamespaceMirrors, :migration,
               :suppress_gitlab_schemas_validate_connection, schema: 20211208122200 do
  let(:namespaces) { table(:namespaces) }
  let(:ci_namespace_mirrors) { table(:ci_namespace_mirrors) }

  subject { described_class.new }

  describe '#perform' do
    it 'creates hierarchies for all namespaces in range' do
      namespaces.create!(id: 5, name: 'test1', path: 'test1')
      namespaces.create!(id: 7, name: 'test2', path: 'test2')
      namespaces.create!(id: 8, name: 'test3', path: 'test3')

      subject.perform(5, 7)

      expect(ci_namespace_mirrors.all).to contain_exactly(
        an_object_having_attributes(namespace_id: 5, traversal_ids: [5]),
        an_object_having_attributes(namespace_id: 7, traversal_ids: [7])
      )
    end

    it 'handles existing hierarchies gracefully' do
      namespaces.create!(id: 5, name: 'test1', path: 'test1')
      test2 = namespaces.create!(id: 7, name: 'test2', path: 'test2')
      namespaces.create!(id: 8, name: 'test3', path: 'test3', parent_id: 7)
      namespaces.create!(id: 9, name: 'test4', path: 'test4')

      # Simulate a situation where a user has had a chance to move a group to another parent
      # before the background migration has had a chance to run
      test2.update!(parent_id: 5)
      ci_namespace_mirrors.create!(namespace_id: test2.id, traversal_ids: [5, 7])

      subject.perform(5, 8)

      expect(ci_namespace_mirrors.all).to contain_exactly(
        an_object_having_attributes(namespace_id: 5, traversal_ids: [5]),
        an_object_having_attributes(namespace_id: 7, traversal_ids: [5, 7]),
        an_object_having_attributes(namespace_id: 8, traversal_ids: [5, 7, 8])
      )
    end
  end
end
