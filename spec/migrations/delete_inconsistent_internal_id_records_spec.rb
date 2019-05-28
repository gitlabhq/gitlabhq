# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180723130817_delete_inconsistent_internal_id_records.rb')

describe DeleteInconsistentInternalIdRecords, :migration do
  let!(:namespace) { table(:namespaces).create!(name: 'test', path: 'test') }
  let!(:project1) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:project2) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:project3) { table(:projects).create!(namespace_id: namespace.id) }

  let(:internal_ids) { table(:internal_ids) }
  let(:internal_id_query) { ->(project) { InternalId.where(usage: InternalId.usages[scope.to_s.tableize], project_id: project.id) } }

  let(:create_models) do
    [project1, project2, project3].each do |project|
      3.times do |i|
        attributes = required_attributes.merge(project_id: project.id,
                                               iid: i.succ)

        table(scope.to_s.pluralize).create!(attributes)
      end
    end
  end

  shared_examples_for 'deleting inconsistent internal_id records' do
    before do
      create_models

      [project1, project2, project3].each do |project|
        internal_ids.create!(project_id: project.id, usage: InternalId.usages[scope.to_s.tableize], last_value: 3)
      end

      internal_id_query.call(project1).first.tap do |iid|
        iid.last_value = iid.last_value - 2
        # This is an inconsistent record
        iid.save!
      end

      internal_id_query.call(project3).first.tap do |iid|
        iid.last_value = iid.last_value + 2
        # This is a consistent record
        iid.save!
      end
    end

    it "deletes inconsistent records" do
      expect { migrate! }.to change { internal_id_query.call(project1).size }.from(1).to(0)
    end

    it "retains consistent records" do
      expect { migrate! }.not_to change { internal_id_query.call(project2).size }
    end

    it "retains consistent records, especially those with a greater last_value" do
      expect { migrate! }.not_to change { internal_id_query.call(project3).size }
    end
  end

  context 'for issues' do
    let(:scope) { :issue }
    let(:required_attributes) { {} }

    it_behaves_like 'deleting inconsistent internal_id records'
  end

  context 'for merge_requests' do
    let(:scope) { :merge_request }

    let(:create_models) do
      [project1, project2, project3].each do |project|
        3.times do |i|
          table(:merge_requests).create!(
            target_project_id: project.id,
            source_project_id: project.id,
            target_branch: 'master',
            source_branch: j.to_s,
            iid: i.succ
          )
        end
      end
    end

    it_behaves_like 'deleting inconsistent internal_id records'
  end

  context 'for deployments' do
    let(:scope) { :deployment }
    let(:deployments) { table(:deployments) }

    let(:create_models) do
      3.times { |i| deployments.create!(project_id: project1.id, iid: i, environment_id: 1, ref: 'master', sha: 'a', tag: false) }
      3.times { |i| deployments.create!(project_id: project2.id, iid: i, environment_id: 1, ref: 'master', sha: 'a', tag: false) }
      3.times { |i| deployments.create!(project_id: project3.id, iid: i, environment_id: 1, ref: 'master', sha: 'a', tag: false) }
    end

    it_behaves_like 'deleting inconsistent internal_id records'
  end

  context 'for milestones (by project)' do
    let(:scope) { :milestone }
    let(:required_attributes) { { title: 'test' } }

    it_behaves_like 'deleting inconsistent internal_id records'
  end

  context 'for ci_pipelines' do
    let(:scope) { :ci_pipeline }
    let(:required_attributes) { { ref: 'test' } }

    it_behaves_like 'deleting inconsistent internal_id records'
  end

  context 'for milestones (by group)' do
    # milestones (by group) is a little different than most of the other models
    let(:groups) { table(:namespaces) }
    let(:group1) { groups.create(name: 'Group 1', type: 'Group', path: 'group_1') }
    let(:group2) { groups.create(name: 'Group 2', type: 'Group', path: 'group_2') }
    let(:group3) { groups.create(name: 'Group 2', type: 'Group', path: 'group_3') }

    let(:internal_id_query) { ->(group) { InternalId.where(usage: InternalId.usages['milestones'], namespace_id: group.id) } }

    before do
      [group1, group2, group3].each do |group|
        3.times do |i|
          table(:milestones).create!(
            group_id: group.id,
            title: 'test',
            iid: i.succ
          )
        end

        internal_ids.create!(namespace_id: group.id, usage: InternalId.usages['milestones'], last_value: 3)
      end

      internal_id_query.call(group1).first.tap do |iid|
        iid.last_value = iid.last_value - 2
        # This is an inconsistent record
        iid.save!
      end

      internal_id_query.call(group3).first.tap do |iid|
        iid.last_value = iid.last_value + 2
        # This is a consistent record
        iid.save!
      end
    end

    it "deletes inconsistent records" do
      expect { migrate! }.to change { internal_id_query.call(group1).size }.from(1).to(0)
    end

    it "retains consistent records" do
      expect { migrate! }.not_to change { internal_id_query.call(group2).size }
    end

    it "retains consistent records, especially those with a greater last_value" do
      expect { migrate! }.not_to change { internal_id_query.call(group3).size }
    end
  end
end
