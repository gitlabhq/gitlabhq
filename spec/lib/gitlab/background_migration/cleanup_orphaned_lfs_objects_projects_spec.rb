# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CleanupOrphanedLfsObjectsProjects, schema: 20210514063252 do
  let(:lfs_objects_projects) { table(:lfs_objects_projects) }
  let(:lfs_objects) { table(:lfs_objects) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace') }
  let(:project) { projects.create!(namespace_id: namespace.id) }
  let(:another_project) { projects.create!(namespace_id: namespace.id) }
  let(:lfs_object) { lfs_objects.create!(oid: 'abcdef', size: 1) }
  let(:another_lfs_object) { lfs_objects.create!(oid: '1abcde', size: 2) }

  let!(:without_object1) { create_object(project_id: project.id) }
  let!(:without_object2) { create_object(project_id: another_project.id) }
  let!(:without_object3) { create_object(project_id: another_project.id) }
  let!(:with_project_and_object1) { create_object(project_id: project.id, lfs_object_id: lfs_object.id) }
  let!(:with_project_and_object2) { create_object(project_id: project.id, lfs_object_id: another_lfs_object.id) }
  let!(:with_project_and_object3) { create_object(project_id: another_project.id, lfs_object_id: another_lfs_object.id) }
  let!(:without_project1) { create_object(lfs_object_id: lfs_object.id) }
  let!(:without_project2) { create_object(lfs_object_id: another_lfs_object.id) }
  let!(:without_project_and_object) { create_object }

  def create_object(project_id: non_existing_record_id, lfs_object_id: non_existing_record_id)
    lfs_objects_project = nil

    ActiveRecord::Base.connection.disable_referential_integrity do
      lfs_objects_project = lfs_objects_projects.create!(project_id: project_id, lfs_object_id: lfs_object_id)
    end

    lfs_objects_project
  end

  subject { described_class.new }

  describe '#perform' do
    it 'lfs_objects_projects without an existing lfs object or project are removed' do
      subject.perform(without_object1.id, without_object3.id)

      expect(lfs_objects_projects.all).to match_array([
        with_project_and_object1, with_project_and_object2, with_project_and_object3,
        without_project1, without_project2, without_project_and_object
      ])

      subject.perform(with_project_and_object1.id, with_project_and_object3.id)

      expect(lfs_objects_projects.all).to match_array([
        with_project_and_object1, with_project_and_object2, with_project_and_object3,
        without_project1, without_project2, without_project_and_object
      ])

      subject.perform(without_project1.id, without_project_and_object.id)

      expect(lfs_objects_projects.all).to match_array([
        with_project_and_object1, with_project_and_object2, with_project_and_object3
      ])

      expect(lfs_objects.ids).to contain_exactly(lfs_object.id, another_lfs_object.id)
      expect(projects.ids).to contain_exactly(project.id, another_project.id)
    end

    it 'cache for affected projects is being reset' do
      expect(ProjectCacheWorker).to receive(:bulk_perform_in) do |delay, args|
        expect(delay).to eq(1.minute)
        expect(args).to match_array([[project.id, [], [:lfs_objects_size]], [another_project.id, [], [:lfs_objects_size]]])
      end

      subject.perform(without_object1.id, with_project_and_object1.id)

      expect(ProjectCacheWorker).not_to receive(:bulk_perform_in)

      subject.perform(with_project_and_object1.id, with_project_and_object3.id)

      expect(ProjectCacheWorker).not_to receive(:bulk_perform_in)

      subject.perform(without_project1.id, without_project_and_object.id)
    end
  end
end
