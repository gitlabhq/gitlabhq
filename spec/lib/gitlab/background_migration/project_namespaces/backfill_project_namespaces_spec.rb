# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ProjectNamespaces::BackfillProjectNamespaces, :migration, schema: 20220326161803 do
  include MigrationsHelpers

  RSpec.shared_examples 'backfills project namespaces' do
    context 'when migrating data', :aggregate_failures do
      let(:projects) { table(:projects) }
      let(:namespaces) { table(:namespaces) }

      let(:parent_group1) { namespaces.create!(name: 'parent_group1', path: 'parent_group1', visibility_level: 20, type: 'Group') }
      let(:parent_group2) { namespaces.create!(name: 'test1', path: 'test1', runners_token: 'my-token1', project_creation_level: 1, visibility_level: 20, type: 'Group') }

      let(:parent_group1_project) { projects.create!(name: 'parent_group1_project', path: 'parent_group1_project', namespace_id: parent_group1.id, visibility_level: 20) }
      let(:parent_group2_project) { projects.create!(name: 'parent_group2_project', path: 'parent_group2_project', namespace_id: parent_group2.id, visibility_level: 20) }

      let(:child_nodes_count) { 2 }
      let(:tree_depth) { 3 }

      let(:backfilled_namespace) { nil }

      before do
        BackfillProjectNamespaces::TreeGenerator.new(namespaces, projects, [parent_group1, parent_group2], child_nodes_count, tree_depth).build_tree
      end

      describe '#up' do
        shared_examples 'back-fill project namespaces' do
          it 'back-fills all project namespaces' do
            start_id = ::Project.minimum(:id)
            end_id = ::Project.maximum(:id)
            projects_count = ::Project.count
            batches_count = (projects_count / described_class::SUB_BATCH_SIZE.to_f).ceil
            project_namespaces_count = ::Namespace.where(type: 'Project').count
            migration = described_class.new

            expect(projects_count).not_to eq(project_namespaces_count)
            expect(migration).to receive(:batch_insert_namespaces).exactly(batches_count).and_call_original
            expect(migration).to receive(:batch_update_projects).exactly(batches_count).and_call_original
            expect(migration).to receive(:batch_update_project_namespaces_traversal_ids).exactly(batches_count).and_call_original

            expect { migration.perform(start_id, end_id, nil, nil, nil, nil, nil, 'up') }.to change(Namespace.where(type: 'Project'), :count)

            expect(projects_count).to eq(::Namespace.where(type: 'Project').count)
            check_projects_in_sync_with(Namespace.where(type: 'Project'))
          end

          context 'when passing specific group as parameter' do
            let(:backfilled_namespace) { parent_group1 }

            it 'back-fills project namespaces for the specified group hierarchy' do
              backfilled_namespace_projects = base_ancestor(backfilled_namespace).first.all_projects
              start_id = backfilled_namespace_projects.minimum(:id)
              end_id = backfilled_namespace_projects.maximum(:id)
              group_projects_count = backfilled_namespace_projects.count
              batches_count = (group_projects_count / described_class::SUB_BATCH_SIZE.to_f).ceil
              project_namespaces_in_hierarchy = project_namespaces_in_hierarchy(base_ancestor(backfilled_namespace))

              migration = described_class.new

              expect(project_namespaces_in_hierarchy.count).to eq(0)
              expect(migration).to receive(:batch_insert_namespaces).exactly(batches_count).and_call_original
              expect(migration).to receive(:batch_update_projects).exactly(batches_count).and_call_original
              expect(migration).to receive(:batch_update_project_namespaces_traversal_ids).exactly(batches_count).and_call_original

              expect(group_projects_count).to eq(14)
              expect(project_namespaces_in_hierarchy.count).to eq(0)

              migration.perform(start_id, end_id, nil, nil, nil, nil, backfilled_namespace.id, 'up')

              expect(project_namespaces_in_hierarchy.count).to eq(14)
              check_projects_in_sync_with(project_namespaces_in_hierarchy)
            end
          end

          context 'when projects already have project namespaces' do
            before do
              hierarchy1_projects = base_ancestor(parent_group1).first.all_projects
              start_id = hierarchy1_projects.minimum(:id)
              end_id = hierarchy1_projects.maximum(:id)

              described_class.new.perform(start_id, end_id, nil, nil, nil, nil, parent_group1.id, 'up')
            end

            it 'does not duplicate project namespaces' do
              # check there are already some project namespaces but not for all
              projects_count = ::Project.count
              start_id = ::Project.minimum(:id)
              end_id = ::Project.maximum(:id)
              batches_count = (projects_count / described_class::SUB_BATCH_SIZE.to_f).ceil
              project_namespaces = ::Namespace.where(type: 'Project')
              migration = described_class.new

              expect(project_namespaces_in_hierarchy(base_ancestor(parent_group1)).count).to be >= 14
              expect(project_namespaces_in_hierarchy(base_ancestor(parent_group2)).count).to eq(0)
              expect(projects_count).not_to eq(project_namespaces.count)

              # run migration again to test we do not generate extra project namespaces
              expect(migration).to receive(:batch_insert_namespaces).exactly(batches_count).and_call_original
              expect(migration).to receive(:batch_update_projects).exactly(batches_count).and_call_original
              expect(migration).to receive(:batch_update_project_namespaces_traversal_ids).exactly(batches_count).and_call_original

              expect { migration.perform(start_id, end_id, nil, nil, nil, nil, nil, 'up') }.to change(project_namespaces, :count).by(14)

              expect(projects_count).to eq(project_namespaces.count)
            end
          end
        end

        it 'checks no project namespaces exist in the defined hierarchies' do
          hierarchy1_project_namespaces = project_namespaces_in_hierarchy(base_ancestor(parent_group1))
          hierarchy2_project_namespaces = project_namespaces_in_hierarchy(base_ancestor(parent_group2))
          hierarchy1_projects_count = base_ancestor(parent_group1).first.all_projects.count
          hierarchy2_projects_count = base_ancestor(parent_group2).first.all_projects.count

          expect(hierarchy1_project_namespaces).to be_empty
          expect(hierarchy2_project_namespaces).to be_empty
          expect(hierarchy1_projects_count).to eq(14)
          expect(hierarchy2_projects_count).to eq(14)
        end

        context 'back-fill project namespaces in a single batch' do
          it_behaves_like 'back-fill project namespaces'
        end

        context 'back-fill project namespaces in batches' do
          before do
            stub_const("#{described_class.name}::SUB_BATCH_SIZE", 2)
          end

          it_behaves_like 'back-fill project namespaces'
        end
      end

      describe '#down' do
        before do
          start_id = ::Project.minimum(:id)
          end_id = ::Project.maximum(:id)
          # back-fill first
          described_class.new.perform(start_id, end_id, nil, nil, nil, nil, nil, 'up')
        end

        shared_examples 'cleanup project namespaces' do
          it 'removes project namespaces' do
            projects_count = ::Project.count
            start_id = ::Project.minimum(:id)
            end_id = ::Project.maximum(:id)
            migration = described_class.new
            batches_count = (projects_count / described_class::SUB_BATCH_SIZE.to_f).ceil

            expect(projects_count).to be > 0
            expect(projects_count).to eq(::Namespace.where(type: 'Project').count)

            expect(migration).to receive(:nullify_project_namespaces_in_projects).exactly(batches_count).and_call_original
            expect(migration).to receive(:delete_project_namespace_records).exactly(batches_count).and_call_original

            migration.perform(start_id, end_id, nil, nil, nil, nil, nil, 'down')

            expect(::Project.count).to be > 0
            expect(::Namespace.where(type: 'Project').count).to eq(0)
          end

          context 'when passing specific group as parameter' do
            let(:backfilled_namespace) { parent_group1 }

            it 'removes project namespaces only for the specific group hierarchy' do
              backfilled_namespace_projects = base_ancestor(backfilled_namespace).first.all_projects
              start_id = backfilled_namespace_projects.minimum(:id)
              end_id = backfilled_namespace_projects.maximum(:id)
              group_projects_count = backfilled_namespace_projects.count
              batches_count = (group_projects_count / described_class::SUB_BATCH_SIZE.to_f).ceil
              project_namespaces_in_hierarchy = project_namespaces_in_hierarchy(base_ancestor(backfilled_namespace))
              migration = described_class.new

              expect(project_namespaces_in_hierarchy.count).to eq(14)
              expect(migration).to receive(:nullify_project_namespaces_in_projects).exactly(batches_count).and_call_original
              expect(migration).to receive(:delete_project_namespace_records).exactly(batches_count).and_call_original

              migration.perform(start_id, end_id, nil, nil, nil, nil, backfilled_namespace.id, 'down')

              expect(::Namespace.where(type: 'Project').count).to be > 0
              expect(project_namespaces_in_hierarchy.count).to eq(0)
            end
          end
        end

        context 'cleanup project namespaces in a single batch' do
          it_behaves_like 'cleanup project namespaces'
        end

        context 'cleanup project namespaces in batches' do
          before do
            stub_const("#{described_class.name}::SUB_BATCH_SIZE", 2)
          end

          it_behaves_like 'cleanup project namespaces'
        end
      end
    end
  end

  it_behaves_like 'backfills project namespaces'

  context 'when namespaces.id is bigint' do
    before do
      namespaces.connection.execute("ALTER TABLE namespaces ALTER COLUMN id TYPE bigint")
    end

    it_behaves_like 'backfills project namespaces'
  end

  def base_ancestor(ancestor)
    ::Namespace.where(id: ancestor.id)
  end

  def project_namespaces_in_hierarchy(base_node)
    Gitlab::ObjectHierarchy.new(base_node).base_and_descendants.where(type: 'Project')
  end

  def check_projects_in_sync_with(namespaces)
    project_namespaces_attrs = namespaces.order(:id).pluck(:id, :name, :path, :parent_id, :visibility_level, :shared_runners_enabled)
    corresponding_projects_attrs = Project.where(project_namespace_id: project_namespaces_attrs.map(&:first))
                                     .order(:project_namespace_id).pluck(:project_namespace_id, :name, :path, :namespace_id, :visibility_level, :shared_runners_enabled)

    expect(project_namespaces_attrs).to eq(corresponding_projects_attrs)
  end
end

module BackfillProjectNamespaces
  class TreeGenerator
    def initialize(namespaces, projects, parent_nodes, child_nodes_count, tree_depth)
      parent_nodes_ids = parent_nodes.map(&:id)

      @namespaces = namespaces
      @projects = projects
      @subgroups_depth = tree_depth
      @resource_count = child_nodes_count
      @all_groups = [parent_nodes_ids]
    end

    def build_tree
      (1..@subgroups_depth).each do |level|
        parent_level = level - 1
        current_level = level
        parent_groups = @all_groups[parent_level]

        parent_groups.each do |parent_id|
          @resource_count.times do |i|
            group_path = "child#{i}_level#{level}"
            project_path = "project#{i}_level#{level}"
            sub_group = @namespaces.create!(name: group_path, path: group_path, parent_id: parent_id, visibility_level: 20, type: 'Group')
            @projects.create!(name: project_path, path: project_path, namespace_id: sub_group.id, visibility_level: 20)

            track_group_id(current_level, sub_group.id)
          end
        end
      end
    end

    def track_group_id(depth_level, group_id)
      @all_groups[depth_level] ||= []
      @all_groups[depth_level] << group_id
    end
  end
end
