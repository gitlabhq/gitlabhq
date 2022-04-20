# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixDuplicateProjectNameAndPath, :migration, schema: 20220325155953 do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:routes) { table(:routes) }

  let(:namespace1) { namespaces.create!(name: 'batchtest1', type: 'Group', path: 'batch-test1') }
  let(:namespace2) { namespaces.create!(name: 'batchtest2', type: 'Group', parent_id: namespace1.id, path: 'batch-test2') }
  let(:namespace3) { namespaces.create!(name: 'batchtest3', type: 'Group', parent_id: namespace2.id, path: 'batch-test3') }

  let(:project_namespace2) { namespaces.create!(name: 'project2', path: 'project2', type: 'Project', parent_id: namespace2.id, visibility_level: 20) }
  let(:project_namespace3) { namespaces.create!(name: 'project3', path: 'project3', type: 'Project', parent_id: namespace3.id, visibility_level: 20) }

  let(:project1) { projects.create!(name: 'project1', path: 'project1', namespace_id: namespace1.id, visibility_level: 20) }
  let(:project2) { projects.create!(name: 'project2', path: 'project2', namespace_id: namespace2.id, project_namespace_id: project_namespace2.id, visibility_level: 20) }
  let(:project2_dup) { projects.create!(name: 'project2', path: 'project2', namespace_id: namespace2.id, visibility_level: 20) }
  let(:project3) { projects.create!(name: 'project3', path: 'project3', namespace_id: namespace3.id, project_namespace_id: project_namespace3.id, visibility_level: 20) }
  let(:project3_dup) { projects.create!(name: 'project3', path: 'project3', namespace_id: namespace3.id, visibility_level: 20) }

  let!(:namespace_route1) { routes.create!(path: 'batch-test1', source_id: namespace1.id, source_type: 'Namespace') }
  let!(:namespace_route2) { routes.create!(path: 'batch-test1/batch-test2', source_id: namespace2.id, source_type: 'Namespace') }
  let!(:namespace_route3) { routes.create!(path: 'batch-test1/batch-test3', source_id: namespace3.id, source_type: 'Namespace') }

  let!(:proj_route1) { routes.create!(path: 'batch-test1/project1', source_id: project1.id, source_type: 'Project') }
  let!(:proj_route2) { routes.create!(path: 'batch-test1/batch-test2/project2', source_id: project2.id, source_type: 'Project') }
  let!(:proj_route2_dup) { routes.create!(path: "batch-test1/batch-test2/project2-route-#{project2_dup.id}", source_id: project2_dup.id, source_type: 'Project') }
  let!(:proj_route3) { routes.create!(path: 'batch-test1/batch-test3/project3', source_id: project3.id, source_type: 'Project') }
  let!(:proj_route3_dup) { routes.create!(path: "batch-test1/batch-test3/project3-route-#{project3_dup.id}", source_id: project3_dup.id, source_type: 'Project') }

  subject(:perform_migration) { migration.perform(projects.minimum(:id), projects.maximum(:id)) }

  describe '#up' do
    it 'backfills namespace_id for the selected records', :aggregate_failures do
      expect(namespaces.where(type: 'Project').count).to eq(2)

      perform_migration

      expect(namespaces.where(type: 'Project').count).to eq(5)

      expect(project1.reload.name).to eq("project1-#{project1.id}")
      expect(project1.path).to eq('project1')

      expect(project2.reload.name).to eq('project2')
      expect(project2.path).to eq('project2')

      expect(project2_dup.reload.name).to eq("project2-#{project2_dup.id}")
      expect(project2_dup.path).to eq("project2-route-#{project2_dup.id}")

      expect(project3.reload.name).to eq("project3")
      expect(project3.path).to eq("project3")

      expect(project3_dup.reload.name).to eq("project3-#{project3_dup.id}")
      expect(project3_dup.path).to eq("project3-route-#{project3_dup.id}")

      projects.all.each do |pr|
        project_namespace = namespaces.find(pr.project_namespace_id)
        expect(project_namespace).to be_in_sync_with_project(pr)
      end
    end
  end
end
