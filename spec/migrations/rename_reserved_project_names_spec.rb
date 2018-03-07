# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20161221153951_rename_reserved_project_names.rb')

# This migration is using factories, which set fields that don't actually
# exist in the DB schema previous to 20161221153951. Thus we just use the
# latest schema when testing this migration.
# This is ok-ish because:
#   1. This migration is a data migration
#   2. It only relies on very stable DB fields: routes.id, routes.path, namespaces.id, projects.namespace_id
# Ideally, the test should not use factories and rely on the `table` helper instead.
describe RenameReservedProjectNames, :migration, schema: :latest do
  let(:migration) { described_class.new }
  let!(:project) { create(:project) }

  before do
    project.path = 'projects'
    project.save!(validate: false)
  end

  describe '#up' do
    context 'when project repository exists' do
      before do
        project.create_repository
      end

      context 'when no exception is raised' do
        it 'renames project with reserved names' do
          migration.up

          expect(project.reload.path).to eq('projects0')
        end
      end

      context 'when exception is raised during rename' do
        before do
          allow(project).to receive(:rename_repo).and_raise(StandardError)
        end

        it 'captures exception from project rename' do
          expect { migration.up }.not_to raise_error
        end
      end
    end

    context 'when project repository does not exist' do
      it 'does not raise error' do
        expect { migration.up }.not_to raise_error
      end
    end
  end
end
